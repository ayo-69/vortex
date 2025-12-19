module main

import vortex
import time

fn main() {
	mut app := &vortex.App{}

	app.use(vortex.logging())

	mut api := app.router.group('/api/v1')

	api.get('/hello', fn (mut ctx vortex.Context) bool {
		ctx.json('{"message": "Hello from vortex!}", "time": "${time.now}"')
		return false
	})

	api.get('/ping', fn (mut ctx vortex.Context) bool {
		ctx.text('pong')
		return false
	})

	app.serve() or { panic('Failed to start; ${err}') }
}
