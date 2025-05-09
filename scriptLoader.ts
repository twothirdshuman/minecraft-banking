const script = Deno.readFile("./atm.lua");

export async function scriptEndpoint(): Promise<Response> {
    return new Response(await script);
}