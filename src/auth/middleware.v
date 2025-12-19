module auth

import vortex

pub fn require_auth() vortex.Middleware {
	return vortex.Middleware{
		handler: fn (mut ctx vortex.Context) bool {
			auth_header := ctx.req.header.get(.authorization) or { '' }

			if !auth_header.starts_with('Bearer ') {
				ctx.status(.unauthorized)
				ctx.json({
					'error': 'missing authorization header'
				})
				return false
			}

			token := auth_header[7..].trim_space()

			user_info := verify_token(token) or {
				ctx.status(.unauthorized)
				ctx.json({
					'error': 'invalid or expired token'
				})
				return false
			}

			ctx.data = user_info.clone()

			return true
		}
	}
}

// TODO: Implement role based middleware
