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

// Single role
pub fn require_role(required_role string) vortex.Middleware {
	middleware_fn := fn (role string) vortex.Middleware {
		return vortex.Middleware{
			handler: fn [role] (mut ctx vortex.Context) bool {
				user_role := ctx.data['role'] or { '' }
				if user_role != role {
					ctx.status(.forbidden)
					ctx.json({
						'error': 'forbidden: insufficient role'
					})
					return false
				}
				return true
			}
		}
	}
	return middleware_fn(required_role)
}

// Multiple roles
pub fn require_roles(allowed_roles ...string) vortex.Middleware {
	return vortex.Middleware{
		handler: fn [allowed_roles] (mut ctx vortex.Context) bool {
			role := ctx.data['role'] or { '' }
			if role !in allowed_roles {
				ctx.status(.forbidden)
				ctx.json({
					'error': 'forbidden: insufficient role'
				})
				return false
			}
			return true
		}
	}
}
