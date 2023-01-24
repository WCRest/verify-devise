Warden::Manager.after_authentication do |user, auth, options|
  if user.respond_to?(:with_verify_authentication?)
    if auth.session(options[:scope])[:with_verify_authentication] = user.with_verify_authentication?(auth.request)
      auth.session(options[:scope])[:id] = user.id
    end
  end
end
