module vortex

import net.http

pub struct Route {
	method     string
	path       string
	handler    HandlerFn = unsafe { nil }
	middleware []Middleware
}

pub struct RouterGroup {
pub mut:
	prefix     string
	middleware []Middleware
	routes     []Route
}

pub struct Router {
pub mut:
	groups    []RouterGroup
	not_found HandlerFn = fn (mut ctx Context) bool {
		ctx.not_found()
		return false
	}
}

pub fn new_router() &Router {
	return &Router{}
}

pub fn (mut r Router) group(prefix string, mids ...Middleware) &RouterGroup {
	mut group := RouterGroup{
		prefix:     prefix
		middleware: mids
	}
	r.groups << group
	return &r.groups[r.groups.len - 1]
}

pub fn (mut g RouterGroup) handle(method string, path string, handler HandlerFn, mids ...Middleware) {
	g.routes << Route{
		method:     method
		path:       g.prefix + path
		handler:    handler
		middleware: mids
	}
}

pub fn (mut g RouterGroup) get(path string, handler HandlerFn, mids ...Middleware) {
	g.handle('GET', path, handler, ...mids)
}

pub fn (mut g RouterGroup) post(path string, handler HandlerFn, mids ...Middleware) {
	g.handle('POST', path, handler, ...mids)
}

pub fn (mut g RouterGroup) put(path string, handler HandlerFn, mids ...Middleware) {
	g.handle('PUT', path, handler, ...mids)
}

pub fn (mut g RouterGroup) delete(path string, handler HandlerFn, mids ...Middleware) {
	g.handle('DELETE', path, handler, ...mids)
}

// TODO: Implement params later
pub fn (r &Router) match(req http.Request) ?(HandlerFn, []Middleware, map[string]string) {
	for group in r.groups {
		for route in group.routes {
			if req.method.str() == route.method && req.url == route.path {
				mut combined_middleware := route.middleware.clone()
				combined_middleware << group.middleware
				return route.handler, combined_middleware, map[string]string{}
			}
		}
	}

	return none
}
