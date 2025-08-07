import plugin from 'tailwindcss/plugin'
import defaultTheme from 'tailwindcss/defaultTheme'
import containerQueriesPlugin from '@tailwindcss/container-queries'

/** @type {import('tailwindcss').Config} */
export default {
  content: ['./applications/**/*.{vue,js,ts,mdx}', './vuci-ui-core/src/index.html', './vuci-ui-core/src/src/**/*.{vue,js,ts,mdx}', './vuci-ui-core/src/ui-core/**/*.{vue,js,ts,mdx}'],
  safelist: [
    {
      pattern: /text-body-.*/
    }
  ],
  theme: {
    extend: {
      screens: {
        '3xl': '1660px',
        '4xl': '1920px',
        '5xl': '2048px',
        xs: '320px'
      },
      containers: {
        '2xs': '15rem'
      },
      borderRadius: {
        'sm-2': '0.25rem'
      },
      width: {
        84: '21rem',
        88: '22rem',
        92: '23rem'
      },
      // https://tailwindcss.com/docs/font-size#providing-a-default-line-height
      fontSize: {
        '4xl': '2rem',
        fish: ['1.25rem', '1.5rem'], // 20/24
        salmon: ['1.5rem', '2rem'], // 24/32
        turtle: ['2rem', '2.5rem'], // 32/40
        seal: ['2.5rem', '3rem'], // 40/48
        dolphin: ['3rem', '3.5rem'], // 48/56
        'body-main': ['1rem', '1.5rem'], // 16/24
        'body-secondary': ['0.875rem', '1.25rem'], // 14/20
        caption: ['0.75rem', '1rem'], // 12/16
        'caption-sm': ['0.625rem', '0.75rem'] // 10/12
      },
      fontFamily: {
        sans: ['Open Sans', ...defaultTheme.fontFamily.sans]
      },
      colors: {
        success: {
          100: useOpacity('var(--clr-success-100)'),
          200: useOpacity('var(--clr-success-200)'),
          300: useOpacity('var(--clr-success-300)')
        },
        warning: {
          100: useOpacity('var(--clr-warning-100)'),
          200: useOpacity('var(--clr-warning-200)'),
          300: useOpacity('var(--clr-warning-300)')
        },
        error: {
          50: useOpacity('var(--clr-error-50)'),
          100: useOpacity('var(--clr-error-100)'),
          200: useOpacity('var(--clr-error-200)'),
          250: useOpacity('var(--clr-error-250)'),
          300: useOpacity('var(--clr-error-300)'),
          400: useOpacity('var(--clr-error-400)')
        },
        placeholder: useOpacity('var(--clr-placeholder)'),
        primary: {
          100: useOpacity('var(--clr-primary-100)'),
          200: useOpacity('var(--clr-primary-200)'),
          250: useOpacity('var(--clr-primary-250)'),
          300: useOpacity('var(--clr-primary-300)'),
          400: useOpacity('var(--clr-primary-400)'),
          450: useOpacity('var(--clr-primary-450)'),
          500: useOpacity('var(--clr-primary-500)'),
          dm: {
            100: useOpacity('var(--clr-primary-dm-100)')
          }
        },
        gray: {
          tlt: {
            50: useOpacity('var(--clr-gray-50)'),
            75: useOpacity('var(--clr-gray-75)'),
            100: useOpacity('var(--clr-gray-100)'),
            200: useOpacity('var(--clr-gray-200)'),
            250: useOpacity('var(--clr-gray-250)'),
            300: useOpacity('var(--clr-gray-300)'),
            400: useOpacity('var(--clr-gray-400)'),
            500: useOpacity('var(--clr-gray-500)'),
            600: useOpacity('var(--clr-gray-600)')
          }
        },
        'primary-gray': {
          100: useOpacity('var(--clr-primary-gray-100)'),
          200: useOpacity('var(--clr-primary-gray-200)')
        },
        light: {
          tlt: {
            100: useOpacity('var(--clr-light-blue-100)'),
            150: useOpacity('var(--clr-light-blue-150)'),
            200: useOpacity('var(--clr-light-blue-200)'),
            300: useOpacity('var(--clr-light-blue-300)'),
            400: useOpacity('var(--clr-light-blue-400)')
          }
        },
        accent: {
          success: {
            100: useOpacity('var(--clr-accent-success-100)'),
            200: useOpacity('var(--clr-accent-success-200)'),
            300: useOpacity('var(--clr-accent-success-300)')
          },
          warning: {
            100: useOpacity('var(--clr-accent-warning-100)'),
            200: useOpacity('var(--clr-accent-warning-200)'),
            300: useOpacity('var(--clr-accent-warning-300)')
          },
          active: {
            100: useOpacity('var(--clr-accent-active-100)'),
            200: useOpacity('var(--clr-accent-active-200)'),
            300: useOpacity('var(--clr-accent-active-300)')
          },
          purple: {
            100: useOpacity('var(--clr-accent-purple-100)'),
            200: useOpacity('var(--clr-accent-purple-200)'),
            300: useOpacity('var(--clr-accent-purple-300)')
          }
        }
      },
      animation: {
        wiggle: 'wiggle 1s ease 1'
      },
      keyframes: {
        wiggle: {
          from: { rotate: '0deg' },
          '16.667%': { rotate: '15deg' },
          '33.334%': { rotate: '-15deg' },
          '50%': { rotate: '15deg' },
          '66.667%': { rotate: '-15deg' },
          '83.334%': { rotate: '15deg' },
          to: { rotate: '0deg' }
        }
      },
      // https://github.com/tailwindlabs/tailwindcss/discussions/8705
      gridTemplateColumns: (theme: (selector: string) => Record<string, string>) => {
        const spacing = theme('spacing')
        return Object.keys(spacing).reduce((accumulator, spacingKey) => {
          return {
            ...accumulator,
            [`fill-${spacingKey}`]: `repeat(auto-fill, minmax(${spacing[spacingKey]}, 1fr))`,
            [`fit-${spacingKey}`]: `repeat(auto-fit, minmax(${spacing[spacingKey]}, 1fr))`
          }
        }, {})
      }
    }
  },
  plugins: [
    containerQueriesPlugin,
    plugin(function ({ addVariant }) {
      addVariant('item-left', ['[data-item-left="true"] &', '&[data-item-left="true"]'])
      addVariant('item-right', ['[data-item-right="true"] &', '&[data-item-right="true"]'])
      addVariant('hocus', ['&:hover', '&:focus'])
    })
  ]
}

function useOpacity(colorVar: string): ({ opacityValue }: { opacityValue: number }) => string {
  return ({ opacityValue }) => `rgba(${colorVar}, ${opacityValue ?? 1})`
}
