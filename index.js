import { NativeModules } from 'react-native'
import { wrap } from './wrap'

const reader = wrap(NativeModules.RNRegulaDocumentReader)
const initialize = reader.initialize
const scan = async opts => {
  await initialize()
  return await reader.scan(opts)
}

const Scenario = {
  mrz: 'Mrz',
  ocr: 'Ocr',
  barcode: 'Barcode',
}

export default {
  initialize,
  scan,
  Scenario,
}
