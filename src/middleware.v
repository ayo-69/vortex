module vortex

import net.http
import time

pub type HandlerFn = fn (mut Context) bool  // return false to stop chain

pub struct Middleware {
	handler HandlerFn
}

pub fn (m &Middleware) handle(mut ctx Context) bool {
	return m.handler(mut ctx)
}

// Logging middleware
pub fn logging () Middleware {
	return  Middleware{
		handler: fn (mut ctx Context) bool {
			start := time.now()
			println('[${time.now().format_ss_micro()}] ${ctx.req.method} ${ctx.req.url}')
			return true
	 	}
	}
}

// TODO: Complete implementation
/*pub fn recorvery() Middleware {
	return Middleware{
		handler: fn (mut ctx Context) bool {
			defer {
				if err := recorver() {
					println('Recovered panic: ${err}')
					ctx.server_error('Internal Server Error')
				}
			}
				return true
		}
	}
}
*/
