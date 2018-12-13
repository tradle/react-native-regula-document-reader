const promisify = fn => (...args) => new Promise((resolve, reject) => fn(...args, (err, result) => {
  if (err) return reject(new Error(err))

  if (typeof result === 'string') {
    result = JSON.parse(result)
  }

  resolve(result)
}))

const memoize = fn => {
  let val
  return async (...args) => {
    if (!val) {
      val = fn(...args)
      val.catch(err => {
        // allow retry after fail
        val = null
      })
    }

    return val
  }
}

const oneAtATime = (fn, name) => {
  let promise = Promise.resolve()
  return (...args) => {
    const run = () => fn(...args)
    return promise = promise.then(run, run)
  }
}

const promisifyObj = obj => Object.keys(obj).reduce((wrapper, key) => {
  const val = obj[key]
  if (typeof val === 'function') {
    wrapper[key] = promisify(val.bind(obj))
  } else {
    wrapper[key] = val
  }

  return wrapper
}, {})

const validators = {
  initialize: opts => {
    if (!opts.licenseKey) throw new Error('expected base64-encoded string "licenseKey"')
  },
  scan: opts => {},
  prepareDatabase: opts => {},
}

const wrapWithValidator = (fn, validate) => async (...args) => {
  validate(...args)
  return fn(...args)
}

export const wrap = reader => {
  const wrapper = promisifyObj(reader)
  const initialize = memoize(oneAtATime(wrapper.initialize))
  const scan = oneAtATime(wrapper.scan)
  wrapper.initialize = wrapWithValidator(initialize, validators.initialize)
  wrapper.scan = wrapWithValidator(scan, validators.scan)
  wrapper.prepareDatabase = wrapWithValidator(wrapper.prepareDatabase, validators.prepareDatabase)
  return wrapper
}
