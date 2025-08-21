import { type Plugin } from 'vite'
import fg from 'fast-glob'
import fs, { promises as fsp } from 'fs'
import path from 'path'

const readAndParse = (path: string) => JSON.parse(fs.readFileSync(path, 'utf-8'))
const notFound: { application: string; path: string; view: string; filePath: string }[] = []
const unknownApps: string[] = []

export type DeviceApp = 'general' | 'tsw' | 'tap'

type VuciOptions = {
  /** @description should the vuci-menu js output be minified. */
  minify?: boolean
} & (
  | {
      /** @description which apps to prioritize in case of vuci app name collision. If left undefined - collisions won't we removed */
      target?: DeviceApp
      plugins?: never
      coreApps?: never
    }
  | {
      /** @description which apps to prioritize in case of vuci app name collision. If left undefined - collisions won't we removed */
      target?: never
      plugins?: string[]
      coreApps: string[]
    }
)

export default function VuCI(pluginOptions: VuciOptions): Plugin {
  const target = pluginOptions.coreApps
    ? [...pluginOptions.coreApps, ...(pluginOptions.plugins || [])].map(appName => (appName.endsWith('-ui') ? appName.slice(0, -3) : appName))
    : pluginOptions.target || null
  const minify = pluginOptions.minify || false
  const filterStrategy = (entries: MenuEntry[]) => {
    if (!target) return entries
    if (Array.isArray(target)) {
      const coveredApps: string[] = []
      const result = entries.filter(entry => {
        const res = target.includes(entry.app)
        res && !coveredApps.includes(entry.app) && coveredApps.push(entry.app)
        return res
      })
      if (target.length > coveredApps.length) unknownApps.push(...target.filter(a => !coveredApps.includes(a)))
      return result
    } else {
      console.log('Solving menu entry conflicts. Targeted device: ' + target)
      if (target === 'general') return entries.filter(g => g.device === target)
      const collisions = entries.reduce<string[]>((sum, g) => {
        if (g.device !== 'general' && target === g.device) {
          const app = getAppName(g.app)
          if (!sum.includes(app)) sum.push(app)
        }
        return sum
      }, [])
      return entries.filter(group => group.device === target || (group.device === 'general' && !collisions.includes(group.app)))
    }
  }
  return {
    name: 'VuCI',
    buildStart: {
      sequential: true,
      order: 'pre',
      async handler() {
        const { views, menus } = await groupMenusToViews()
        let grouped = groupByApp(menus, views, target)
          .map(groupRoutes)
          .flat()
          .sort((a, b) => a.app.localeCompare(b.app))
        if (notFound.length) {
          console.log("Some menu.d json files references views that does not exist in that application's scope:")
          notFound.forEach((v, i) => console.log(`${i + 1}. ${green(v.filePath)} @${green(v.path)} -> ${red(v.view)}`))
          console.log("Maybe files are located in another application's directories?")
        } else console.log('All menu.d references successfully mapped to views!')
        grouped = filterStrategy(grouped)
        if (unknownApps.length) {
          this.warn(
            'Some selected apps could not be found:\n\n' +
              unknownApps.map((v, i) => `${i + 1}. ${yellow(v)}`).join(',\n') +
              '\nThis may cause failing build if files from these folders are not referenced anywhere.\n'
          )
        }
        const format = minify ? formatMini : formatRoute

        this.info('Formatting the file contents...')
        const fileContent = `
// Generated at: ${today().format('YYYY-MM-DD hh:mm:ss')}
export const routes = [
  ${grouped.map(format).join(',\n  ')}
] as const

export type RoutePath = (typeof routes)[number]['path']`
        const pathTs = new URL('../vuci-menu.ts', import.meta.url)
        this.info('Writing menu contents to ' + green(pathTs.pathname))
        fsp.writeFile(pathTs, fileContent.trim() + '\n')
        this.info('Contents successfully written to ' + green(pathTs.pathname))
        const pathJs = new URL('../vuci-menu.js', import.meta.url)
        if (fs.existsSync(pathJs)) {
          this.info('Deleting old file ' + green(pathJs.pathname))
          fsp.rm(pathJs)
        }
      }
    },
    writeBundle: {
      sequential: true,
      order: 'post',
      handler(options) {
        const dir = options.dir!
        const applicationsDir = path.resolve(dir, '../applications')
        if (fs.existsSync(applicationsDir)) {
          fs.rmSync(applicationsDir, {
            recursive: true,
            force: true
          })
        }
        const files = fs.readdirSync(dir + '/assets')
        if (!pluginOptions.plugins) return
        this.info(`Moving plugin applications out of ${green(dir)}`)
        for (const chunk of files) {
          const name = chunk
          const appName = name.match(/app\.([a-zA-Z0-9-]+)\.app/)?.[1]
          if (!appName) continue
          const appPart = `vuci-app-${appName}`
          if (!pluginOptions.plugins.includes(appPart + '-ui')) continue
          // using path resolve instead of building path with `app/data` in case path separator is different based on os this script is running.
          const newDir = path.resolve(applicationsDir, appPart)
          const oldPath = path.resolve(dir, 'assets', name)
          const newPath = path.resolve(newDir, name)
          createDir(newDir, this.info)
          fs.renameSync(oldPath, newPath)
        }
      }
    }
  }
}

function createDir(dirPath: string, logger: (message: string) => void) {
  if (fs.existsSync(dirPath)) return
  logger('Creating directory: ' + dirPath)
  fs.mkdirSync(dirPath, { recursive: true })
}

type Device = 'general' | 'tsw' | 'tap'

type MenuJson = {
  title: string
  index?: number
  view?: string
  acls?: string[]
}

type MenuEntry = {
  app: string
  group: string
  device: Device
  path: string
  name: string
  view: string
}

function getAppName(name: string) {
  if (name.endsWith('-tsw') || name.endsWith('-tap')) return name.slice(0, name.lastIndexOf('-'))
  return name
}

async function groupMenusToViews() {
  const path = (p: string) => new URL(p, import.meta.url).pathname
  const files = await fg([path('../applications/**/menu.d/*.json'), path('../applications/**/src/views/**/*.vue')])
  return files.reduce<{ menus: string[]; views: string[] }>(
    (sum, curr) => {
      if (curr.endsWith('.vue')) sum.views.push(curr)
      else if (curr.endsWith('.json')) sum.menus.push(curr)
      return sum
    },
    { menus: [], views: [] }
  )
}

const groupByApp = (menus: string[], views: string[], target: string[] | DeviceApp | null) => {
  let viewsCopy = views.slice(0)
  const grouped = menus.map(menu => {
    const appIndex = menu.indexOf('vuci-app-')
    const appName = menu.slice(appIndex, menu.indexOf('/', appIndex + 1))
    const _views = viewsCopy.filter(v => v.includes('applications/' + appName + '/')) // must be a folder, thats why '/' at the end is needed, otherwise similar app views might be removed.
    viewsCopy = viewsCopy.filter(v => !_views.includes(v))
    return {
      app: appName,
      menud: [menu],
      views: _views
    }
  })
  const merged = grouped.reduce<typeof grouped>((sum, curr) => {
    const appInSum = sum.find(v => v.app === curr.app)
    if (appInSum) {
      appInSum.views.push(...curr.views)
      appInSum.menud.push(...curr.menud)
    } else sum.push(curr)
    return sum
  }, [])
  merged.forEach(v => {
    if (typeof target !== 'string' || !v.menud.some(m => m.includes('.tsw.') || m.includes('.tap.'))) return
    if (target === 'general') v.menud = v.menud.filter(m => !m.includes('.tsw.') && !m.includes('.tap.'))
    else if (target === 'tsw') v.menud = v.menud.filter(m => m.includes('.tsw.'))
    else if (target === 'tap') v.menud = v.menud.filter(m => m.includes('.tap.'))
  })
  if (viewsCopy.length) {
    console.log(
      '%s of views have not been used (does not have menu.d/*.json file to reference it). Unused views:\n %s\n',
      viewsCopy.length,
      viewsCopy
        .filter(v => !v.endsWith('Edit.vue'))
        .map((v, i) => `${i + 1}. ${green(v.slice(v.search(/vuci-app-.*-ui/g)))}`)
        .join('\n ')
    )
  }
  return merged
}

type AppEntry = {
  /** @description name of the app */
  app: string
  /** @description path to menu.d/json file */
  menud: string[]
  /** @description views in the application */
  views: string[]
}

const groupRoutes = (app: AppEntry): MenuEntry[] => {
  const device: Device = app.app.endsWith('-tsw') ? 'tsw' : app.app.endsWith('-tap') ? 'tap' : 'general'
  const menu = app.menud.reduce<Record<string, MenuJson>>((sum, path) => {
    const res = readAndParse(path)
    sum = { ...sum, ...res }
    return sum
  }, {})
  const menuEntries = Object.entries(menu)
  const bases = getBaseEntries(menuEntries)
  const result = menuEntries.reduce<MenuEntry[]>((sum, [path, value]) => {
    if (!('view' in value)) return sum
    const view = app.views.find(v => v.endsWith(value.view + '.vue'))
    if (!view) {
      notFound.push({ application: app.app, path, view: value.view!, filePath: app.menud.join(' or ') })
    } else {
      sum.push({
        app: app.app,
        device,
        group: bases.find(b => path.startsWith(b.path))?.name || 'NONE',
        path: path.startsWith('/') ? path : '/' + path,
        name: value.title,
        view: view?.slice(view?.indexOf('applications'))! || 'undefined'
      })
    }
    return sum
  }, [])
  return result
}

function formatMini(menuEntry: MenuEntry) {
  return `
  {
    path: '${menuEntry.path}',
    component: () => import('./${menuEntry.view}')
  }
  `.trim()
}

function formatRoute(menuEntry: MenuEntry) {
  return `
  {
    app: '${menuEntry.app}',
    device: '${menuEntry.device}',
    group: '${menuEntry.group}',
    path: '${menuEntry.path}',
    menuName: '${menuEntry.name}',
    component: () => import('./${menuEntry.view}')
  }
    `.trim()
}

function getBaseEntries(menuEntries: [string, MenuJson][]) {
  const entries: { path: string; name: string }[] = []
  for (const [path, descriptor] of menuEntries) {
    if (!('view' in descriptor) || entries.some(e => e.path === path)) continue
    entries.push({ path, name: descriptor.title })
  }
  return entries
}

function $text(text: string, color: string) {
  const reset = '\x1b[0m'
  return `${color}${text}${reset}`
}

function yellow(text: string) {
  return $text(text, '\x1b[1;33m')
}
function green(text: string) {
  return $text(text, '\x1b[3;32m')
}
function red(text: string) {
  return $text(text, '\x1b[31m')
}

function today(timestamp: number = new Date().getTime()) {
  const date = new Date(timestamp)
  const todayNumbers = [date.getUTCFullYear(), date.getUTCMonth() + 1, date.getUTCDate(), date.getUTCHours(), date.getUTCMinutes(), date.getUTCSeconds()].map(v => v.toString())
  return {
    /** @param format Y - represents year, M - month, D - day, h - hour, m - minute, s - second */
    format(format: string) {
      let copy = format
      const formats = [
        format.match(/(Y+|Y)/)?.[1] || '',
        format.match(/(M+|M)/)?.[1] || '',
        format.match(/(D+|D)/)?.[1] || '',
        format.match(/(h+|h)/)?.[1] || '',
        format.match(/(m+|m)/)?.[1] || '',
        format.match(/(s+|s)/)?.[1] || ''
      ]
      const date = todayNumbers.map((v, i) => {
        const v2 = formats[i]
        return v.padStart(v2.length, '0').slice(-v2.length)
      })
      formats.forEach((match, i) => match && (copy = copy.replace(match, date[i])))
      return copy
    }
  }
}
