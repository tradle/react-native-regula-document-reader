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


export const wrap = reader => {
  const wrapper = promisifyObj(reader)
  wrapper.initialize = memoize(oneAtATime(wrapper.initialize))
  wrapper.scan = oneAtATime(wrapper.scan)
  return wrapper
}
