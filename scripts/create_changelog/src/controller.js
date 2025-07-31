const dataGetters = require('./dataGetters')
const fs = require('fs')

module.exports = { saveChangelogs }

/**
 * @param {*[]} changelogs
 */
async function saveChangelogs(changelogs) {
  const fullIds = dataGetters.getChangelogs()

  fullIds.forEach((fullId) => {
    const id = fullId.split('-')[0]
    const entries = changelogs.filter((changelog) => changelog.caseId === id)
    const path = `${dataGetters.changelogDir}/${fullId}.json`
    const dublicate = fullIds.find((otherId) => otherId.split('-')[0] === id) !== fullId
    if (entries.length > 0 && !dublicate)
      fs.writeFileSync(path, JSON.stringify(entries, undefined, 2) + '\n', { flag: 'w' })
    else fs.rmSync(path)
  })
}
