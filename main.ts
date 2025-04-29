import { ulid } from "jsr:@std/ulid";
import { verify } from "jsr:@bronti/argon2";

const BANK_PASS = "$argon2id$v=19$m=19456,t=2,p=1$Z0HBvINt0WAMvtmUmICkzw$II046EPc50AQPiBPlRlTcmyiPoFTKPMz82RLtKEhP7c";

// kv Key ["accounts", string] and ["transactions", string]
const kv = await Deno.openKv();

type Account = {
    pin: string,
    balance: number,
    name: string
}

type Transaction = {
    fromAccountName: string,
    toAccountName: string,
    amount: number,
    ulid: string
}

async function getAccounts(): Promise<Response> {
    const entries = kv.list({prefix: ["accounts"]});

    const ret = [];
    for await (const entry of entries) {
        const name = entry.key[1];
        if (typeof name !== "string") {
            continue;
        }
        ret.push(name);
    }

    return new Response(JSON.stringify(ret), {
        status: 200,
        headers: {
            "Content-Type": "application/json"
        }
    });
}

async function getAccount(accountName: string): Promise<Account | "Not found"> {
    const account = await kv.get<Account>(["accounts", accountName]);

    if (account.value === null) {
        return "Not found";
    }

    return account.value;
}

async function getBalanceFromAccount(accountName: string): Promise<number | "Not found"> {
    const account = await getAccount(accountName);

    if (account === "Not found") { return "Not found"; }

    const balance = account.balance;

    return balance;
}

async function getBalance(req: Request): Promise<Response> {
    const url = new URL(req.url);
    const accountName = url.searchParams.get("account");
    if (accountName === null) {
        return new Response(null, {status:400});
    }

    const balance = await getBalanceFromAccount(accountName);

    if (balance === "Not found") {
        return new Response("Account not found", {status:404});
    }

    return new Response(JSON.stringify({balance:balance}), {
        headers: {
            "Content-Type": "application/json"
        }
    });
}

async function doTransaction(trans: Transaction): Promise<"Success" | "Fail"> {
    const [fromRes, toRes] = await Promise.all([
        kv.get<Account>(["accounts", trans.fromAccountName]),
        kv.get<Account>(["accounts", trans.toAccountName])
    ]);

    if (fromRes.value === null || toRes.value === null) {
        return "Fail";
    }

    const atomic = kv.atomic()
        .check(fromRes)
        .check(toRes)
        .set(["transactions", trans.ulid], trans)
        .set(["accounts", trans.fromAccountName], {
            ...fromRes.value,
            balance: fromRes.value.balance - trans.amount
        })
        .set(["accounts", trans.toAccountName], {
            ...toRes.value,
            balance: toRes.value.balance + trans.amount
        });

    const commit = await atomic.commit();
    
    if (!commit.ok) {
        return "Fail";
    }

    return "Success";
}

async function makeTransaction(req: Request): Promise<Response> {
    let reqJson: unknown;
    try {
        reqJson = await req.json();
    } catch (_) {
        return new Response(null, {status:400});
    }

    if (typeof reqJson !== "object" || reqJson === null) {
        return new Response(null, {status:400});
    }

    if (!('fromAccountName' in reqJson)) {
        return new Response(null, { status: 400 });
    }

    if (!('toAccountName' in reqJson)) {
        return new Response(null, { status: 400 });
    }

    if (!('amount' in reqJson)) {
        return new Response(null, { status: 400 });
    }

    if (!('pin' in reqJson)) {
        return new Response(null, { status: 401 });
    }

    const from = reqJson?.fromAccountName;
    const to = reqJson?.toAccountName;
    const pin = reqJson?.pin;
    const amount = reqJson?.amount;

    if (typeof from !== "string" || typeof to !== "string" || typeof pin !== "string" || typeof amount !== "number") {
        return new Response(null, { status: 400 });
    }

    const account = await getAccount(from);
    if (account === "Not found") {
        return new Response("Account not found", {status:404});
    }

    if (account.balance < amount) {
        return new Response("Not enough funds", {status:400});
    }

    if (amount <= 0 || Math.round(amount) !== amount || !Number.isFinite(amount)) {
        return new Response("Invalid amount", {status:400});
    }

    if (from === to) {
        return new Response("cannot transfer to self", {status:400});
    }

    if (account.pin !== pin) {
        return new Response("Wrong pin", {status:401});
    }
    
    const result = await doTransaction({
        fromAccountName: from,
        toAccountName: to,
        amount: amount,
        ulid: ulid()
    });

    if (result === "Fail") {
        return new Response(null, {status:500});
    }

    return new Response("Successful transaction");
}

async function printMoney(req: Request): Promise<Response> {
    let reqJson: unknown;
    try {
        reqJson = await req.json();
    } catch (_) {
        return new Response(null, {status:400});
    }

    if (typeof reqJson !== "object" || reqJson === null) {
        return new Response(null, {status:400});
    }

    if (!('toAccountName' in reqJson)) {
        return new Response(null, { status: 400 });
    }

    if (!('amount' in reqJson)) {
        return new Response(null, { status: 400 });
    }

    if (!('pin' in reqJson)) {
        return new Response(null, { status: 401 });
    }

    const to = reqJson?.toAccountName;
    const pin = reqJson?.pin;
    const amount = reqJson?.amount;

    if (typeof to !== "string" || typeof pin !== "string" || typeof amount !== "number") {
        return new Response(null, { status: 400 });
    }

    const verified = verify(pin, BANK_PASS);

    if (!verified) {
        return new Response(null, {status:401});
    }

    const result = await doTransaction({
        fromAccountName: "Printer",
        toAccountName: to,
        amount: amount,
        ulid: ulid()
    });

    if (result === "Fail") {
        return new Response(null, {status:500});
    }

    return new Response("Printed money successfully", {status:200});
}

async function createAccount(req: Request): Promise<Response> {
    let reqJson: unknown;
    try {
        reqJson = await req.json();
    } catch (_) {
        return new Response(null, {status:400});
    }

    if (typeof reqJson !== "object" || reqJson === null) {
        return new Response(null, {status:400});
    }

    if (!('name' in reqJson)) {
        return new Response(null, { status: 400 });
    }

    if (!('pin' in reqJson)) {
        return new Response(null, { status: 401 });
    }

    const name = reqJson?.name;
    const pin = reqJson?.pin;

    if (typeof name !== "string" || typeof pin !== "string") {
        return new Response(null, { status: 400 });
    }

    const verified = verify(pin, BANK_PASS);

    if (!verified) {
        return new Response(null, {status:401});
    }

    const existing = await kv.get(["accounts", name]);
    if (existing.value !== null) {
        return new Response("Account already exists", {status:409});
    }

    const result = await kv.set(["accounts", name], {
        pin: "",
        balance: 0,
        name: name
    });

    if (!result.ok) {
        return new Response(null, {status:500});
    }

    return new Response("Account created successfully");
}

Deno.serve((req) => {
    const url = new URL(req.url);

    if (url.pathname === "/api/getAccounts" && req.method === "GET") {
        return getAccounts();
    } else if (url.pathname === "/api/getBalance" && req.method === "GET") {
        return getBalance(req);
    } else if (url.pathname === "/api/makeTransaction" && req.method === "POST") {
        return makeTransaction(req);
    } else if (url.pathname === "/api/printMoney" && req.method === "POST") {
        return printMoney(req);
    } else if (url.pathname === "/api/createAccount" && req.method === "POST") {
        return createAccount(req);
    } else if(url.pathname === "/" && req.method === "GET") {
        return new Response("This is a website with just an api to keep track of money and transactions in a minecraft server me and some friends are on.");
    }

    return new Response("Not found", {status:404});
})