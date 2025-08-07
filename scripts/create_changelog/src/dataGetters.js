const fs = require('fs')
const execSync = require('child_process').execSync

let isVuciPrepared = false

async function prepareVuci() {
  if (isVuciPrepared) return
  try {
    if (!globalThis.supressInfo) console.log('Updating vuci feeds. This might take a while...')
    execSync('./scripts/feeds update vuci', { cwd: '../../', stdio: 'ignore' })
  } catch (e) {
    console.log('Failed to update vuci: ' + e)
    process.exit(1)
  }
  isVuciPrepared = true
}

module.exports = {
  changelogDir: '../../.gitlab/changelogs',
  deviceHwDir: '../../feeds/vuci/api-documentation/devices',
  spellingDir: '../spelling.txt',
  /** @type {null | Record<string, any>} */
  deviceHwCache: null,
  /** @type {null | Record<string, string>} */
  spellingCache: null,
  /** @type {null | 'rutx_open'| 'tswos'} */
  projectNameCache: null,
  getTypes() {
    return ['New', 'Improvements', 'Fix', 'CVE Patches', 'Updates']
  },
  getCategories() {
    return ['Network', 'Services', 'System']
  },
  getTopics(noDepends = true) {
    const txt = fs.readFileSync('./databases/topics.json', { encoding: 'utf8' })
    return JSON.parse(txt)
  },
  getFamilies(noDevices) {
    const txt = fs.readFileSync('./databases/families.json', { encoding: 'utf8' })
    const parsedData = JSON.parse(txt).map((family) => ({
      type: 'family',
      name: family.name,
      devices: noDevices ? undefined : family.devices,
    }))
    // generating Router family in js as it would require a lot of dublication in json
    if (this.getProjectName() === 'rutx_open') {
      parsedData.push({
        type: 'family',
        name: 'Router',
        devices: noDevices
          ? undefined
          : this.getDevices()
              .map((e) => e.name)
              .filter((e) => !e.startsWith('TAP')),
      })
    }
    return parsedData
  },
  getDevices(raw) {
    if (this.getProjectName() === 'tswos') {
      const txt = fs.readFileSync('./databases/devices.json', { encoding: 'utf8' })
      if (raw) return JSON.parse(txt)
      return JSON.parse(txt).map((device) => ({ type: 'device', name: device }))
    }
    prepareVuci()
    // delete RUT950 after https://git.teltonika.lt/teltonika/rutx_open/-/issues/21615
    const exceptions = ['RUT950']
    const devices = fs
      .readdirSync(this.deviceHwDir)
      .map((device) => device.split('.')[0].toUpperCase())
      .filter((device) => !exceptions.includes(device) && this.getDevicesHw()[device].is_switch === false)
    if (raw) return devices
    return devices.map((device) => ({ type: 'device', name: device }))
  },
  getDepends(noDevices, allPosible) {
    if (this.getProjectName() === 'tswos') {
      return [...this.getDevices(), ...this.getFamilies(noDevices)]
    }
    return [...this.getDevices(), ...this.getFamilies(noDevices), ...this.getHwDepends(allPosible)]
  },
  getChangelog(id, raw) {
    const path = `${this.changelogDir}/${id}.json`
    if (fs.existsSync(path)) {
      const txt = fs.readFileSync(path, { encoding: 'utf8' })
      if (raw) return txt
      return JSON.parse(txt)
    } else {
      return null
    }
  },
  getFullId(id) {
    return this.getChangelogs().find((fileName) => fileName.split('-')[0] === id)
  },
  getChangelogs(full) {
    const changelogFiles = fs.readdirSync(this.changelogDir).filter((file) => file !== '.gitkeep')
    if (full) return changelogFiles
    return changelogFiles.map((file) => file.split('.')[0])
  },
  getJsonFile(name, raw) {
    const path = name
    if (fs.existsSync(path)) {
      const txt = fs.readFileSync(path, { encoding: 'utf8' })
      if (raw) return txt
      return JSON.parse(txt)
    } else {
      return null
    }
  },
  getDevicesHw() {
    if (this.deviceHwCache) return this.deviceHwCache
    prepareVuci()
    const changelogFiles = fs
      .readdirSync(this.deviceHwDir)
      .map((device) => [device.split('.')[0].toUpperCase(), this.getJsonFile(`${this.deviceHwDir}/${device}`)])
    const res = Object.fromEntries(changelogFiles)
    this.deviceHwCache = res
    return res
  },
  getPosibleHwFlags() {
    return [...new Set(Object.values(this.getDevicesHw()).flatMap((deviceHw) => Object.keys(deviceHw)))]
  },
  getHwDepends(allPosible) {
    if (allPosible)
      return this.getPosibleHwFlags().flatMap((hwFlag) => [
        { type: 'hw', name: hwFlag },
        { type: 'hw', name: hwFlag, value: false },
      ])
    // This is just subset. There is too many to be shown in ui
    return [
      { type: 'hw', name: 'mobile' },
      { type: 'hw', name: 'mobile', value: false },
      { type: 'hw', name: 'wifi' },
      { type: 'hw', name: 'wifi', value: false },
      { type: 'hw', name: 'wifi5Ghz' },
      { type: 'hw', name: 'ios' },
      { type: 'hw', name: 'ios', value: false },
      { type: 'hw', name: 'gps' },
      { type: 'hw', name: 'gps', value: false },
      { type: 'hw', name: 'port_link' },
      { type: 'hw', name: 'port_link', value: false },
      { type: 'hw', name: 'usb' },
      { type: 'hw', name: 'usb', value: false },
      { type: 'hw', name: 'flash16mb' },
      { type: 'hw', name: 'flash16mb', value: false },
      { type: 'hw', name: 'poe' },
      { type: 'hw', name: 'has_dot1x_server' },
      { type: 'hw', name: 'rs232'},
      { type: 'hw', name: 'rs485'},
      { type: 'hw', name: 'mbus'},
      { type: 'hw', name: 'dsa' },
      { type: 'hw', name: 'dsa', value: false },
      { type: 'hw', name: 'is_access_point' },
      { type: 'hw', name: 'is_access_point', value: false },
      { type: 'hw', name: 'has_tpm' }
    ]
  },
  /** @return {Record<string, string>} */
  getSpellings() {
    if (this.spellingCache) return this.spellingCache
    if (!fs.existsSync(this.spellingDir)) {
      throw Error('Spelling file missing')
    }
    const txt = fs.readFileSync(this.spellingDir, { encoding: 'utf8' })
    const res = Object.fromEntries(
      txt
        .split('\n')
        .filter((line) => !line.startsWith('#') && line.includes('||'))
        .map((line) => line.split('||'))
    )
    this.spellingCache = res
    return res
  },
  // This is not comprehensive list. Fill if needed.
  irregularVerbs: [
    'bound',
    'broke',
    'brought',
    'built',
    'caught',
    'chose',
    'cut',
    'drew',
    'forbade',
    'found',
    'froze',
    'gave',
    'hid',
    'kept',
    'let',
    'made',
    'overcome',
    'put',
    'set',
    'showed',
    'shrank',
    'shut',
    'sought',
    'sped',
    'spelt',
    'spent',
    'split',
    'thought',
    'threw',
    'told',
    'took',
    'withdrew',
    'wrote',
  ],
  getHistory() {
    const files = this.getChangelogs(true).map((file) => `-- "${this.changelogDir}/${file}"`)
    let stdout = execSync(
      `git log --name-only --no-merges --pretty=format:'{"commit":"%H","authorName":"%aN","authorEmail":"%aE","timestamp":"%at","message": "%f"}' ${files.join(
        ' '
      )}`,
      { encoding: 'utf8' }
    )
    const allCommits = stdout.split('\n\n').reduce((acc, commit) => {
      const commitAndDirs = commit.split('\n')
      const commits = commitAndDirs.filter((e) => e.startsWith('{'))
      const dirs = commitAndDirs.filter((e) => !e.startsWith('{'))
      const changes = dirs.map((file) => file.split('/').at(-1)?.split('-')[0])
      const parsedChanges = commits.map((rawCommit) => {
        const commit = JSON.parse(rawCommit)
        commit.changes = changes
        return commit
      })
      acc.push(...parsedChanges)
      return acc
    }, /** @type {any[]} */ ([]))
    return allCommits
  },
  /**
   * @returns {'rutx_open'| 'tswos'}
   */
  getProjectName() {
    if (this.projectNameCache) return this.projectNameCache
    let stdout = execSync('git config --local remote.origin.url', { encoding: 'utf8' })
    const res = /** @type {'rutx_open'| 'tswos' | undefined} */ (stdout.split('/').at(-1)?.split('.')[0])
    if (!res) throw new Error('failed to get project name')
    this.projectNameCache = res ?? null
    return res
  },
}
