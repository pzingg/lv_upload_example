// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import '../css/app.scss'

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in 'webpack.config.js'.
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import { Socket } from 'phoenix'
//     import socket from './socket'
//
import 'phoenix_html'
import { Socket } from 'phoenix'
import NProgress from 'nprogress'
import { XhrHeaders } from 'xhr'
import { UpChunkOptions, createUpload } from '@mux/upchunk'
import { LiveSocket, SocketOptions, ViewHookInterface } from 'phoenix_live_view'
import { Loader } from '@googlemaps/js-api-loader'


interface ApplicationWindow extends Window {
  liveSocket: LiveSocket
  map: google.maps.Map | null
}

// Simple hook to test types
// https://www.coletiv.com/blog/how-to-use-google-maps-phoenix-live-view/

interface SightingPayload {
  sighting: { lat: number, lng: number }
}

function handleNewSightingFunction(obj: object) {
  const payload = obj as SightingPayload
  const markerPosition = { lat: payload.sighting.lat, lng: payload.sighting.lng }
  console.log(`marker: ${markerPosition}`)

  const marker = new google.maps.Marker({
    position: markerPosition,
    animation: google.maps.Animation.DROP
  })

  // To add the marker to the map, call setMap();
  marker.setMap(window.map)
}

interface MapContainerDataset {
  apikey: string
  lat: string
  lng: string
  zoom: string
}

const GoogleMapsSightings = {
  mounted() {
    const hook = this as unknown as ViewHookInterface;
    this.loadMap(hook.el.dataset as MapContainerDataset)

    // handle new sightings as they show up
    hook.handleEvent('new_sighting', handleNewSightingFunction)
  },
  loadMap(data: MapContainerDataset) {
    // ...additionalOptions,
    const loader = new Loader({
      apiKey: data.apikey,
      version: 'weekly'
    })

    loader.load().then(() => {
      const opts = {
        center: { lat: parseFloat(data.lat), lng: parseFloat(data.lng) },
        zoom: parseInt(data.zoom)
      }
      let map = new google.maps.Map(document.getElementById('map') as HTMLElement, opts)
      window.map = map
    })
  }
}

const MyLiveViewHooks = {
  mapsightings: GoogleMapsSightings
}

// Example uploader to test types
// https://hexdocs.pm/phoenix_live_view/uploads-external.html

// Data returned by FormComponent.set_upchunk_uploader
interface UpChunkMeta {
  uploader: string
  config: string
  ref: string
  uuid: string
  endpoint: string
  temp_dir: string
  path: string
}

interface PhxUploadFile {
  name: string
  size: number
  type: string
  phxRef: string
  lastModified?: number
  lastModifiedDate?: Date
  webkitRelativePath?: string
}

// Used by upChunkUploader and live socket
const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute('content') || ''

// Uploaders
function upChunkUploader(entries: any[], onViewError: any) {
  entries.forEach(entry => {
    // create the upload session with UpChunk
    const meta = entry.meta as UpChunkMeta
    const file = entry.file as PhxUploadFile

    let headers: XhrHeaders = {
      // Content-Type and Content-Range are set by upchunk
      'Content-Disposition': `attachment; filename='${file.name}'`,
      // Sanity check for UpChunk parser plug to reject non-XHR requests
      'X-Requested-With': 'XMLHttpRequest',
      // Prevent replays and cross-site attacks
      'X-CSRF-Token': csrfToken,
      // We use X-Storage-Location to tell the UpChunk parser plug
      // where to put the file chunks.
      'X-Storage-Location': meta.temp_dir,
      // Not used currently, but who knows?
      'X-Correlation-ID': `upchunk:${meta.ref}`
    }
    if (file.lastModified) {
      // Add 'Last-Modified' header Wed, 21 Oct 2015 07:28:00 GMT
      const date = new Date(file.lastModified)
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
      const wday = days[date.getDay()]
      const day = String(date.getDate()).padStart(2, '0')
      const month = months[date.getMonth()]
      const year = date.getFullYear()
      const hours = String(date.getHours()).padStart(2, '0')
      const minutes = String(date.getMinutes()).padStart(2, '0')
      const seconds = String(date.getSeconds()).padStart(2, '0')
      headers['Last-Modified'] = `${wday}, ${day} ${month} ${year} ${hours}:${minutes}:${seconds} GMT`
    }

    let options: UpChunkOptions = { endpoint: meta.endpoint, file: entry.file, headers: headers }
    let upload = createUpload(options)

    // stop uploading in the event of a view error
    onViewError(() => upload.pause())

    // upload error triggers LiveView error
    upload.on('error', (e) => entry.error(e.detail.message))

    // notify progress events to LiveView
    upload.on('progress', (e) => entry.progress(e.detail))
  })
}

const MyLiveViewUploaders = {
  upchunk: upChunkUploader
}


const opts: SocketOptions = {
  params: {
    _csrf_token: csrfToken
  },
  hooks: MyLiveViewHooks,
  uploaders: MyLiveViewUploaders
}

let liveSocket = new LiveSocket('/live', Socket, opts)

// Show progress bar on live navigation and form submits
window.addEventListener('phx:page-loading-start', info => NProgress.start())
window.addEventListener('phx:page-loading-stop', info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()

declare let window: ApplicationWindow
window.liveSocket = liveSocket

