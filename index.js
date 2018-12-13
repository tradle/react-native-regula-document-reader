import { NativeModules } from 'react-native'
import { wrap } from './wrap'

const reader = wrap(NativeModules.RNRegulaDocumentReader)
const { initialize, prepareDatabase } = reader
const scan = async ({ licenseKey, ...opts }) => {
  if (licenseKey) {
    await initialize({ licenseKey })
  }

  return await reader.scan(opts)
}

const Scenario = {
  mrz: 'Mrz',
  ocr: 'Ocr',
  barcode: 'Barcode',
  locate: 'Locate',
  docType: 'DocType',
  mrzOrBarcode: 'MrzOrBarcode',
  mrzOrLocate: 'MrzOrLocate',
  mrzAndLocate: 'MrzAndLocate',
  mrzOrOcr: 'MrzOrOcr',
  mrzOrBarcodeOrOcr: 'MrzOrBarcodeOrOcr',
  locateVisual_And_MrzOrOcr: 'LocateVisual_And_MrzOrOcr',
  fullProcess: 'FullProcess',
  id3Rus: 'Id3Rus',
}

export default {
  initialize,
  scan,
  prepareDatabase,
  Scenario,
}
