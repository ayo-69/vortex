module vortex

import net.http
import net

pub struct App {
pub mut:
	router &Router = new_router()
	global_middleware []Middleware
}

pub fn (mut app App) use(mids ...Middleware) {
	app.global_middleware << mids
}

pub fn (app &App) serve() ! {
	mut server := http.Server{
		handler: app
		addr: ':8080'
	}
	server.listen_and_serve()
}

pub fn (app &App) handle(mut req http.Request) http.Response {
	mut resp := http.Response{
		status_code: 200
		header: http.Header{}
		body: []u8{}
	}

	mut ctx := Context{
		req: req
		resp: resp
		params: map[string]string{}
		start_mono: time.sys_mono_now()
	}

	// match routes
	if matched := app.router.match(req) {
		handler, route_mids, params := matched
		ctx.params = params

		mut chain := []Middleware{}
		chain << app.global_middleware
		chain << route_mids
		chain << Middleware{ handler: handler }

		for i in 0..chain.len {
			ctx.index = i
			if !chain[i].handle(mut ctx) {
				break
			}
		}
	} else {
		app.router.not_found(mut ctx)
	}

	return ctx.resp
}
