const promisify = fn => (...args) => new Promise((resolve, reject) => {
  fn(...args, (err, result) => {
    if (err) return reject(new Error(err))

    if (typeof result === 'string') {
      result = JSON.parse(result)
    }

    resolve(result)
  })
})

const memoize = fn => {
  let val
  return async (...args) => {
    if (!val) {
      val = fn(...args)
    }

    return val
  }
}

export const wrap = reader => Object.keys(reader).reduce((wrapper, key) => {
  const val = wrapper[key]
  if (typeof val === 'function') {
    wrapper[key] = promisify(val.bind(reader))
    if (key === 'init') {
      wrapper[key] = memoize(wrapper[key])
    }
  } else {
    wrapper[key] = val
  }

  return wrapper
}, {})
