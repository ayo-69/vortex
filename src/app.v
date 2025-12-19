module vortex

import time
import net.http
import net

@[heap]
pub struct App {
pub mut:
	router            &Router = new_router()
	global_middleware []Middleware
}

pub fn (mut app App) use(mids ...Middleware) {
	app.global_middleware << mids
}

pub fn (mut app App) serve() ! {
	mut server := http.Server{
		handler: app
		addr:    ':8080'
	}

	server.listen_and_serve()
}

pub fn (app &App) handle(req http.Request) http.Response {
	mut resp := http.Response{
		status_code: 200
		header:      http.Header{}
		body:        ''
	}

	mut ctx := Context{
		req:        req
		resp:       resp
		params:     map[string]string{}
		data:       map[string]string{}
		start_mono: time.sys_mono_now()
	}

	// match routes
	if handler, route_mids, params := app.router.match(req) {
		ctx.params = params.clone()

		mut chain := []Middleware{}
		chain << app.global_middleware
		chain << route_mids
		chain << Middleware{
			handler: handler
		}

		for i in 0 .. chain.len {
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
