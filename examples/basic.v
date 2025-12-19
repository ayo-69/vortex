module main

import vortex

fn main() {
	mut app := &vortex.App{}

	app.use(vortex.logging())

	mut api := app.router.group('/api/v1')

	api.get('/hello', fn(mut ctx vortex.Context) bool {
		ctx.json('{ "message": "Hello from Vortex!"}')
		return false
	})

	app.serve() or { panic('Failed to start: ${err}') }
}
