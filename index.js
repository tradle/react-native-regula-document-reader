import { NativeModules } from 'react-native'
import { wrap } from './wrap'

const reader = wrap(NativeModules.RNRegulaDocumentReader)
const initialize = reader.initialize
const scan = async opts => {
  await initialize()
  return await reader.scan(opts)
}

export default {
  initialize,
  scan,
}
