/* eslint-disable camelcase */
/* eslint-disable no-undef */
import ChilliMD5 from './ChilliMD5.js'
const md5 = new ChilliMD5()
window.md5 = md5

const path = location.pathname.split('/')
path.shift()
path.shift()
path.shift()
const page = path.join('/')
const urlParams = new URLSearchParams(window.location.search) || ''
const ssl = urlParams.get('ssl')
const uamip = urlParams.get('uamip')
const uamport = urlParams.get('uamport')
const userurl = urlParams.get('userurl')
const uamUrl = ssl || `http://${uamip}:${uamport}/`

function trial_access() {
  const agree = document.getElementById('agreetos')?.checked ? '&agreetos=1' : ''
  const location = new URL(`${uamUrl}trial?userurl=${userurl}${agree}`)
  window.location = location.href
}
window.trial_access = trial_access

window.addEventListener('load', function () {
  const trial_link = document.getElementById('trial_link')
  if (trial_link) {
    trial_link.addEventListener('click', function () {
      trial_access()
    })
  }

  const backbtn = document.getElementById('backbtn')
  if (backbtn) {
    backbtn.addEventListener('click', function () {
      window.history.length > 1 ? window.history.go(-1) : window.close()
    })
  }
})

function smsauthSignupRoute() {
  window.onload = function () {
    const form = document.querySelector('form')
    if (!form) return

    form.onsubmit = function (e) {
      e.preventDefault()
      const formData = new FormData(e.target)
      const phone = formData.get('phone')
      const location = new URL(`${uamUrl}smssignup?phone=${phone}`)
      window.location = location.href
      return false
    }
  }
}

function smsauthLoginRoute() {
  window.onload = function () {
    const form = document.querySelector('form')
    if (!form) return

    form.onsubmit = function (e) {
      e.preventDefault()
      const formData = new FormData(e.target)
      const password = formData.get('password')
      const challenge = urlParams.get('challenge')
      const agree = document.getElementById('agreetos')?.checked ? '&agreetos=1' : ''

      const pappassword = md5.pap(challenge, password, uamsecret)
      const location = new URL(`${uamUrl}logon?username=&password=${pappassword}${agree}`)
      window.location = location.href
      return false
    }
  }
}

// --------- router -----------
switch (page) {
  case 'userpass':
    // -------- userpass / login.htm -----------
    window.onload = function () {
      const form = document.getElementById('login-form')
      if (!form) return

      form.onsubmit = function (e) {
        // username and password login
        e.preventDefault()
        const formData = new FormData(e.target)
        const username = formData.get('username')
        const password = formData.get('password')
        const challenge = urlParams.get('challenge')
        const agree = document.getElementById('agreetos')?.checked ? '&agreetos=1' : ''
        let userurl = urlParams.get('userurl')
        userurl = userurl ? encodeURIComponent(userurl) : ''

        if (auth_proto === 'pap') {
          const pw = md5.pap(challenge, password, uamsecret)
          const location = new URL(`${uamUrl}logon?username=${username}&password=${pw}&userurl=${userurl}${agree}`)
          window.location = location.href
        } else {
          const pw = md5.chap('00', password, challenge, uamsecret)
          const location = new URL(`${uamUrl}logon?username=${username}&response=${pw}&userurl=${userurl}${agree}`)
          window.location = location.href
        }
        return false
      }
    }
    break

  case 'userpass/signup':
    // -------- userpass/signup / signup.htm -----------
    window.onload = function () {
      const form = document.querySelector('form')
      if (!form) return

      form.onsubmit = function (e) {
        e.preventDefault()
        // email, phone and password signup

        const formData = new FormData(e.target)

        const email = formData.get('email')
        const phone = formData.get('phone')
        const password = formData.get('password')
        const confirmPassword = formData.get('confirm_password')

        // validate values
        let valid = true
        const msg = document.getElementById('pw_msg')
        msg.classList.add('hidden')
        if (password !== confirmPassword) {
          msg.classList.remove('hidden')
          valid = false
        }

        if (!valid) return false

        const location = new URL(`${uamUrl}signup?email=${email}&phone=${phone}&password=${password}`)
        window.location = location.href
        return false
      }
    }
    break

  case 'macauth':
    // -------- macauth / login_mac.htm -----------
    window.onload = function () {
      const form = document.querySelector('form')
      if (!form) return

      form.onsubmit = function (e) {
        // username and password login
        e.preventDefault()
        const formData = new FormData(e.target)
        const password = formData.get('password') || ''
        const challenge = urlParams.get('challenge')
        const agree = document.getElementById('agreetos')?.checked ? '&agreetos=1' : ''
        let userurl = urlParams.get('userurl')
        userurl = userurl ? encodeURIComponent(userurl) : ''

        if (auth_proto === 'pap') {
          const pw = md5.pap(challenge, password, uamsecret)
          const location = new URL(`${uamUrl}logon?username=&password=${pw}&userurl=${userurl}${agree}`)
          window.location = location.href
        } else {
          const pw = md5.chap('00', password, challenge, uamsecret)
          const location = new URL(`${uamUrl}logon?username=&response=${pw}&userurl=${userurl}${agree}`)
          window.location = location.href
        }
        return false
      }
    }
    break

  case 'ssoauth':
    // -------- ssoauth / login_sso.htm -----------
    window.onload = function () {
      const form = document.querySelector('form')
      if (!form) return

      form.onsubmit = function (e) {
        e.preventDefault()
        const agree = document.getElementById('agreetos')?.checked ? '&agreetos=1' : ''
        let userurl = urlParams.get('userurl')
        userurl = userurl ? encodeURIComponent(userurl) : ''

        const location = new URL(`${uamUrl}ssologin?userurl=${userurl}${agree}`)
        window.location = location.href
        return false
      }
    }
    break

  case 'smsauth':
    // eslint-disable-next-line
    const res = urlParams.get('res')
    if (urlParams.get('force') === 'login') smsauthLoginRoute()
    else if (urlParams.get('force') === 'signup') smsauthSignupRoute()
    else if (urlParams.get('otpstate') === 'active') smsauthLoginRoute()
    else if (res === 'failed' || res === 'logoff' || res === 'smssuccess') smsauthLoginRoute()
    else if (res === 'notyet' || res === 'smssignup_fail') smsauthSignupRoute()
    else smsauthSignupRoute()
    break
  case 'smsauth/signup':
    smsauthSignupRoute()
    break
  case 'smsauth/login':
    smsauthLoginRoute()
    break
  default:
    break
}
