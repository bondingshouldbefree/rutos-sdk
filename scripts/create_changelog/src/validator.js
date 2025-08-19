const dataGetters = require('./dataGetters')
const process = require('process')

module.exports = { validateChangelogFiles, validateChangelogFile, validateDatabase }

/**
 * @typedef Validation
 * @type {object}
 * @property {string} message
 * @property {'error' | 'warning'} type
 */

function validateChangelogFiles(print = true) {
  const validations = dataGetters.getChangelogs(true).map((file, _, arr) => {
    /** @type {Validation[]} */
    const validations = []
    const idMatch = file.match(/(\d+-).+/)
    if (!file.endsWith('.json'))
      validations.push({
        message: 'file has missing .json extention. You Probably used old format use new one',
        type: 'warning',
      })
    if (!idMatch)
      validations.push({
        message:
          'file  does not start with case id. You probably created changelog from develop or release - rename file to branch name',
        type: 'warning',
      })
    else if (arr.some((other) => other !== file && other.startsWith(idMatch[1])))
      validations.push({
        message: 'two changelog files start with same id. Merge them into one.',
        type: 'warning',
      })

    const id = file.split('.')[0]
    const res = [...validations, ...validateChangelogFile(dataGetters.getChangelog(id, true))]
    return /** @type {[string, Validation[]]}} */ ([id, res])
  })

  if (print) {
    validations.forEach(([id, errors]) => {
      printErrors('changelog', id, errors)
    })
    if (validations.some((e) => e[1].length)) {
      console.log('\x1b[36m%s\x1b[0m', 'Some errors can be fixed by running "./create_changelog.sh auto-fix"')
    }
    if (validations.some((validation) => validation[1].some((error) => error.type === 'error'))) {
      process.exit(1)
    }
  }
  return validations
}

function validateDatabase() {
  const devices = dataGetters.getDevices(true)
  /** @type {Record<string, () => any[]>} */
  const databases = {
    families: () => dataGetters.getFamilies(),
    topics: () => dataGetters.getTopics(),
  }
  const validations = {
    topics: (topic) =>
      validateObject(topic, {
        name: /^[A-Z0-9].*$/,
        category: dataGetters.getCategories(),
        depends: [...dataGetters.getDepends(true, true), undefined],
      }),
    families: (family) =>
      validateObject(family, {
        name: /.*/,
        devices,
      }),
  }
  Object.entries(databases).forEach(([name, database]) => {
    /** @type {any[] | undefined} */
    let parsedDatabase
    try {
      parsedDatabase = database()
    } catch (e) {
      if (e.message.includes('JSON'))
        return printErrors('database', name, [{ message: e.message, type: 'error' }], true)
    }
    if (!Array.isArray(parsedDatabase))
      return printErrors('database', name, [{ message: 'database is not array', type: 'error' }], true)
    /** @type {string[]} */
    const errors = parsedDatabase.reduce(
      (errors, item, index) => [...errors, ...validations[name](item).map((error) => `entry #${index + 1} > ${error}`)],
      /** @type {string[]} */ ([])
    )
    if (name === 'families') {
      const devicesInFamily = parsedDatabase.filter((e) => e.name !== 'Router').flatMap((e) => e.devices)
      const deviceNotInFamily = devices.filter((device) => !devicesInFamily.includes(device))
      errors.push(...deviceNotInFamily.map((e) => `Device ${e} is not found in any family`))
    }

    printErrors(
      'database',
      name,
      errors.map((error) => ({ type: 'warning', message: error }))
    )
  })
}

/**
 * @param {string} changelogTxt
 * @param {string[]} [caseIdOptions]
 * @param {boolean} [disableFormatingCheck]
 * @returns {Validation[]}
 */
function validateChangelogFile(changelogTxt, caseIdOptions, disableFormatingCheck = false) {
  let changelogs
  /** @type {Validation[]} */
  const validations = []
  try {
    changelogs = JSON.parse(changelogTxt)
  } catch (e) {
    return [{ message: e, type: 'error' }]
  }
  if (!Array.isArray(changelogs)) return [{ message: 'changelog file must be array', type: 'error' }]
  const changelogErrors = changelogs.flatMap((changelog, index) => {
    const changlogErrors = validateChangelog(changelog, caseIdOptions)
    return changlogErrors.map(
      /** @returns {Validation} */ (error) => ({ message: `entry #${index + 1} > ${error}`, type: 'warning' })
    )
  })
  validations.push(...changelogErrors)
  if (!disableFormatingCheck && changelogTxt !== JSON.stringify(changelogs, null, 2) + '\n')
    validations.push({
      message: 'file has incorrect JSON formatting.',
      type: 'warning',
    })
  return validations
}

/**
 * @param {*} object
 * @param {string} key
 * @param {string[]} validOptions
 * @returns {string[]}
 */
function validateOption(object, key, validOptions) {
  const validate = (value) => {
    // No options means that prevous values are bad like non-exicsting category will not have topics
    if (validOptions.length === 0) return []
    if (validOptions.some((option) => JSON.stringify(option) === JSON.stringify(value))) return []
    return [`${key}: ${JSON.stringify(value)} does not exist as a option`]
  }
  if (Array.isArray(object[key])) return object[key].flatMap((value) => validate(value))
  else return validate(object[key])
}

/**
 * @param {*} object
 * @param {string} value
 * @param {RegExp} regex
 * @returns {string[]}
 */
function validateRegex(object, value, regex) {
  if (typeof object[value] !== 'string') return [`${value}: "${object[value]}" is not a string`]
  if (regex.test(object[value])) return []
  return [`${value}: "${object[value]}" fails regex "${regex.source}"`]
}

function validateChangelog(changelog, caseIdOptions) {
  const changeValidators = {
    'CVE Patches': /^CVE-\d*-\d*$/,
    Updates: /^[^ ]*$/,
    default: (object, key) => [...validateRegex(object, key, /^[a-z].*[^ .]$/), ...validateChange(object, key)],
  }
  const topicValidators = {
    'CVE Patches': [undefined],
    Updates: /^.*$/,
    default: dataGetters
      .getTopics()
      .filter((e) => e.category === changelog.category)
      .map((e) => e.name),
  }
  const validationRules = {
    type: dataGetters.getTypes(),
    category: ['CVE Patches'].includes(changelog.type) ? [undefined] : dataGetters.getCategories(),
    topic: topicValidators[changelog.type] ?? topicValidators.default,
    depends: dataGetters.getDepends(true),
    change: changeValidators[changelog.type] ?? changeValidators.default,
    caseId: caseIdOptions ?? /^\d*$/,
    notImportant: [true, undefined],
  }
  return validateObject(changelog, validationRules)
}

/**
 * @param {*} object
 * @param {Record<string, RegExp | any[] | function>} rules
 * @returns {string[]}
 */
function validateObject(object, rules) {
  if (typeof object !== 'object') return [`${JSON.stringify(object)} is not a object`]
  return Object.entries(rules).reduce((errors, [value, rule]) => {
    if (!object[value] && !(Array.isArray(rule) && rule.includes(undefined))) errors.push(`${value}: required`)
    else if (rule instanceof RegExp) errors.push(...validateRegex(object, value, rule))
    else if (typeof rule === 'function') errors.push(...rule(object, value))
    else errors.push(...validateOption(object, value, rule))
    return errors
  }, /** @type {string[]} */ ([]))
}

/**
 * @param {Record<string,string>} object
 * @returns {string[]}
 */
function validateChange(object, key) {
  const res = []
  const words = object[key].split(' ')
  if (!(!words[0] || dataGetters.irregularVerbs.includes(words[0]) || words[0].endsWith('ed')))
    res.push(`first word "${words[0]}" is not past tense`)
  res.push(
    ...words
      .filter((word) => dataGetters.getSpellings()[word])
      .map((mistake) => `common mistake: "${mistake}" instead of "${dataGetters.getSpellings()[mistake]}"`)
  )
  return res.map((e) => `${key}: ${e}`)
}

/** @type {Record<Validation['type'], string>} */
const colors = {
  error: '\x1b[41m',
  warning: '\x1b[43m',
}
/**
 * Prints errors and warnings
 * @param {string} group
 * @param {string} name
 * @param {Validation[]} validations
 * @param {boolean} [exitOnError]
 */
function printErrors(group, name, validations, exitOnError) {
  if (!validations.length) return
  const errorsFound = validations.some((e) => e.type === 'error')
  if (!globalThis.supressInfo || errorsFound) {
    console.error(
      `${group} "${name}":\n${validations?.map((e) => `  ${colors[e.type]} ${e.type} \x1b[0m ${e.message}`).join('\n')}`
    )
  }
  if (exitOnError && errorsFound) process.exit(1)
  process.exitCode = 1
}
