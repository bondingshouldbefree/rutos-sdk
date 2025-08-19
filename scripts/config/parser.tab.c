/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison implementation for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output, and Bison version.  */
#define YYBISON 30802

/* Bison version string.  */
#define YYBISON_VERSION "3.8.2"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 0

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1




/* First part of user prologue.  */


#include <ctype.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#include "lkc.h"
#include "internal.h"

#define printd(mask, fmt...) if (cdebug & (mask)) printf(fmt)

#define PRINTD		0x0001
#define DEBUG_PARSE	0x0002

int cdebug = PRINTD;

static void yyerror(const char *err);
static void zconfprint(const char *err, ...);
static void zconf_error(const char *err, ...);
static bool zconf_endtoken(const char *tokenname,
			   const char *expected_tokenname);

struct symbol *symbol_hash[SYMBOL_HASHSIZE];

struct menu *current_menu, *current_entry;



# ifndef YY_CAST
#  ifdef __cplusplus
#   define YY_CAST(Type, Val) static_cast<Type> (Val)
#   define YY_REINTERPRET_CAST(Type, Val) reinterpret_cast<Type> (Val)
#  else
#   define YY_CAST(Type, Val) ((Type) (Val))
#   define YY_REINTERPRET_CAST(Type, Val) ((Type) (Val))
#  endif
# endif
# ifndef YY_NULLPTR
#  if defined __cplusplus
#   if 201103L <= __cplusplus
#    define YY_NULLPTR nullptr
#   else
#    define YY_NULLPTR 0
#   endif
#  else
#   define YY_NULLPTR ((void*)0)
#  endif
# endif

#include "parser.tab.h"
/* Symbol kind.  */
enum yysymbol_kind_t
{
  YYSYMBOL_YYEMPTY = -2,
  YYSYMBOL_YYEOF = 0,                      /* "end of file"  */
  YYSYMBOL_YYerror = 1,                    /* error  */
  YYSYMBOL_YYUNDEF = 2,                    /* "invalid token"  */
  YYSYMBOL_T_HELPTEXT = 3,                 /* T_HELPTEXT  */
  YYSYMBOL_T_WORD = 4,                     /* T_WORD  */
  YYSYMBOL_T_WORD_QUOTE = 5,               /* T_WORD_QUOTE  */
  YYSYMBOL_T_BOOL = 6,                     /* T_BOOL  */
  YYSYMBOL_T_CHOICE = 7,                   /* T_CHOICE  */
  YYSYMBOL_T_CLOSE_PAREN = 8,              /* T_CLOSE_PAREN  */
  YYSYMBOL_T_COLON_EQUAL = 9,              /* T_COLON_EQUAL  */
  YYSYMBOL_T_COMMENT = 10,                 /* T_COMMENT  */
  YYSYMBOL_T_CONFIG = 11,                  /* T_CONFIG  */
  YYSYMBOL_T_DEFAULT = 12,                 /* T_DEFAULT  */
  YYSYMBOL_T_DEF_BOOL = 13,                /* T_DEF_BOOL  */
  YYSYMBOL_T_DEF_TRISTATE = 14,            /* T_DEF_TRISTATE  */
  YYSYMBOL_T_DEPENDS = 15,                 /* T_DEPENDS  */
  YYSYMBOL_T_ENDCHOICE = 16,               /* T_ENDCHOICE  */
  YYSYMBOL_T_ENDIF = 17,                   /* T_ENDIF  */
  YYSYMBOL_T_ENDMENU = 18,                 /* T_ENDMENU  */
  YYSYMBOL_T_HELP = 19,                    /* T_HELP  */
  YYSYMBOL_T_DETAIL = 20,                  /* T_DETAIL  */
  YYSYMBOL_T_TOOLTIP = 21,                 /* T_TOOLTIP  */
  YYSYMBOL_T_HEX = 22,                     /* T_HEX  */
  YYSYMBOL_T_IF = 23,                      /* T_IF  */
  YYSYMBOL_T_IMPLY = 24,                   /* T_IMPLY  */
  YYSYMBOL_T_INT = 25,                     /* T_INT  */
  YYSYMBOL_T_MAINMENU = 26,                /* T_MAINMENU  */
  YYSYMBOL_T_MENU = 27,                    /* T_MENU  */
  YYSYMBOL_T_MENUCONFIG = 28,              /* T_MENUCONFIG  */
  YYSYMBOL_T_MODULES = 29,                 /* T_MODULES  */
  YYSYMBOL_T_ON = 30,                      /* T_ON  */
  YYSYMBOL_T_OPEN_PAREN = 31,              /* T_OPEN_PAREN  */
  YYSYMBOL_T_OPTIONAL = 32,                /* T_OPTIONAL  */
  YYSYMBOL_T_PLUS_EQUAL = 33,              /* T_PLUS_EQUAL  */
  YYSYMBOL_T_PROMPT = 34,                  /* T_PROMPT  */
  YYSYMBOL_T_RANGE = 35,                   /* T_RANGE  */
  YYSYMBOL_T_RESET = 36,                   /* T_RESET  */
  YYSYMBOL_T_MAINTAINER = 37,              /* T_MAINTAINER  */
  YYSYMBOL_T_LABEL = 38,                   /* T_LABEL  */
  YYSYMBOL_T_SELECT = 39,                  /* T_SELECT  */
  YYSYMBOL_T_SOURCE = 40,                  /* T_SOURCE  */
  YYSYMBOL_T_STRING = 41,                  /* T_STRING  */
  YYSYMBOL_T_TRISTATE = 42,                /* T_TRISTATE  */
  YYSYMBOL_T_VISIBLE = 43,                 /* T_VISIBLE  */
  YYSYMBOL_T_EOL = 44,                     /* T_EOL  */
  YYSYMBOL_T_ASSIGN_VAL = 45,              /* T_ASSIGN_VAL  */
  YYSYMBOL_T_OR = 46,                      /* T_OR  */
  YYSYMBOL_T_AND = 47,                     /* T_AND  */
  YYSYMBOL_T_EQUAL = 48,                   /* T_EQUAL  */
  YYSYMBOL_T_UNEQUAL = 49,                 /* T_UNEQUAL  */
  YYSYMBOL_T_LESS = 50,                    /* T_LESS  */
  YYSYMBOL_T_LESS_EQUAL = 51,              /* T_LESS_EQUAL  */
  YYSYMBOL_T_GREATER = 52,                 /* T_GREATER  */
  YYSYMBOL_T_GREATER_EQUAL = 53,           /* T_GREATER_EQUAL  */
  YYSYMBOL_T_NOT = 54,                     /* T_NOT  */
  YYSYMBOL_YYACCEPT = 55,                  /* $accept  */
  YYSYMBOL_input = 56,                     /* input  */
  YYSYMBOL_mainmenu_stmt = 57,             /* mainmenu_stmt  */
  YYSYMBOL_stmt_list = 58,                 /* stmt_list  */
  YYSYMBOL_stmt_list_in_choice = 59,       /* stmt_list_in_choice  */
  YYSYMBOL_config_entry_start = 60,        /* config_entry_start  */
  YYSYMBOL_config_stmt = 61,               /* config_stmt  */
  YYSYMBOL_menuconfig_entry_start = 62,    /* menuconfig_entry_start  */
  YYSYMBOL_menuconfig_stmt = 63,           /* menuconfig_stmt  */
  YYSYMBOL_config_option_list = 64,        /* config_option_list  */
  YYSYMBOL_config_option = 65,             /* config_option  */
  YYSYMBOL_choice = 66,                    /* choice  */
  YYSYMBOL_choice_entry = 67,              /* choice_entry  */
  YYSYMBOL_choice_end = 68,                /* choice_end  */
  YYSYMBOL_choice_stmt = 69,               /* choice_stmt  */
  YYSYMBOL_choice_option_list = 70,        /* choice_option_list  */
  YYSYMBOL_choice_option = 71,             /* choice_option  */
  YYSYMBOL_type = 72,                      /* type  */
  YYSYMBOL_logic_type = 73,                /* logic_type  */
  YYSYMBOL_default = 74,                   /* default  */
  YYSYMBOL_if_entry = 75,                  /* if_entry  */
  YYSYMBOL_if_end = 76,                    /* if_end  */
  YYSYMBOL_if_stmt = 77,                   /* if_stmt  */
  YYSYMBOL_if_stmt_in_choice = 78,         /* if_stmt_in_choice  */
  YYSYMBOL_menu = 79,                      /* menu  */
  YYSYMBOL_menu_entry = 80,                /* menu_entry  */
  YYSYMBOL_menu_end = 81,                  /* menu_end  */
  YYSYMBOL_menu_stmt = 82,                 /* menu_stmt  */
  YYSYMBOL_menu_option_list = 83,          /* menu_option_list  */
  YYSYMBOL_source_stmt = 84,               /* source_stmt  */
  YYSYMBOL_comment = 85,                   /* comment  */
  YYSYMBOL_comment_stmt = 86,              /* comment_stmt  */
  YYSYMBOL_comment_option_list = 87,       /* comment_option_list  */
  YYSYMBOL_help_start = 88,                /* help_start  */
  YYSYMBOL_help = 89,                      /* help  */
  YYSYMBOL_detail_start = 90,              /* detail_start  */
  YYSYMBOL_detail_cond = 91,               /* detail_cond  */
  YYSYMBOL_detail = 92,                    /* detail  */
  YYSYMBOL_tooltip_start = 93,             /* tooltip_start  */
  YYSYMBOL_tooltip_type = 94,              /* tooltip_type  */
  YYSYMBOL_tooltip_cond = 95,              /* tooltip_cond  */
  YYSYMBOL_tooltip = 96,                   /* tooltip  */
  YYSYMBOL_depends = 97,                   /* depends  */
  YYSYMBOL_visible = 98,                   /* visible  */
  YYSYMBOL_prompt_stmt_opt = 99,           /* prompt_stmt_opt  */
  YYSYMBOL_end = 100,                      /* end  */
  YYSYMBOL_if_expr = 101,                  /* if_expr  */
  YYSYMBOL_expr = 102,                     /* expr  */
  YYSYMBOL_nonconst_symbol = 103,          /* nonconst_symbol  */
  YYSYMBOL_symbol = 104,                   /* symbol  */
  YYSYMBOL_word_opt = 105,                 /* word_opt  */
  YYSYMBOL_assignment_stmt = 106,          /* assignment_stmt  */
  YYSYMBOL_assign_op = 107,                /* assign_op  */
  YYSYMBOL_assign_val = 108                /* assign_val  */
};
typedef enum yysymbol_kind_t yysymbol_kind_t;




#ifdef short
# undef short
#endif

/* On compilers that do not define __PTRDIFF_MAX__ etc., make sure
   <limits.h> and (if available) <stdint.h> are included
   so that the code can choose integer types of a good width.  */

#ifndef __PTRDIFF_MAX__
# include <limits.h> /* INFRINGES ON USER NAME SPACE */
# if defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stdint.h> /* INFRINGES ON USER NAME SPACE */
#  define YY_STDINT_H
# endif
#endif

/* Narrow types that promote to a signed type and that can represent a
   signed or unsigned integer of at least N bits.  In tables they can
   save space and decrease cache pressure.  Promoting to a signed type
   helps avoid bugs in integer arithmetic.  */

#ifdef __INT_LEAST8_MAX__
typedef __INT_LEAST8_TYPE__ yytype_int8;
#elif defined YY_STDINT_H
typedef int_least8_t yytype_int8;
#else
typedef signed char yytype_int8;
#endif

#ifdef __INT_LEAST16_MAX__
typedef __INT_LEAST16_TYPE__ yytype_int16;
#elif defined YY_STDINT_H
typedef int_least16_t yytype_int16;
#else
typedef short yytype_int16;
#endif

/* Work around bug in HP-UX 11.23, which defines these macros
   incorrectly for preprocessor constants.  This workaround can likely
   be removed in 2023, as HPE has promised support for HP-UX 11.23
   (aka HP-UX 11i v2) only through the end of 2022; see Table 2 of
   <https://h20195.www2.hpe.com/V2/getpdf.aspx/4AA4-7673ENW.pdf>.  */
#ifdef __hpux
# undef UINT_LEAST8_MAX
# undef UINT_LEAST16_MAX
# define UINT_LEAST8_MAX 255
# define UINT_LEAST16_MAX 65535
#endif

#if defined __UINT_LEAST8_MAX__ && __UINT_LEAST8_MAX__ <= __INT_MAX__
typedef __UINT_LEAST8_TYPE__ yytype_uint8;
#elif (!defined __UINT_LEAST8_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST8_MAX <= INT_MAX)
typedef uint_least8_t yytype_uint8;
#elif !defined __UINT_LEAST8_MAX__ && UCHAR_MAX <= INT_MAX
typedef unsigned char yytype_uint8;
#else
typedef short yytype_uint8;
#endif

#if defined __UINT_LEAST16_MAX__ && __UINT_LEAST16_MAX__ <= __INT_MAX__
typedef __UINT_LEAST16_TYPE__ yytype_uint16;
#elif (!defined __UINT_LEAST16_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST16_MAX <= INT_MAX)
typedef uint_least16_t yytype_uint16;
#elif !defined __UINT_LEAST16_MAX__ && USHRT_MAX <= INT_MAX
typedef unsigned short yytype_uint16;
#else
typedef int yytype_uint16;
#endif

#ifndef YYPTRDIFF_T
# if defined __PTRDIFF_TYPE__ && defined __PTRDIFF_MAX__
#  define YYPTRDIFF_T __PTRDIFF_TYPE__
#  define YYPTRDIFF_MAXIMUM __PTRDIFF_MAX__
# elif defined PTRDIFF_MAX
#  ifndef ptrdiff_t
#   include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  endif
#  define YYPTRDIFF_T ptrdiff_t
#  define YYPTRDIFF_MAXIMUM PTRDIFF_MAX
# else
#  define YYPTRDIFF_T long
#  define YYPTRDIFF_MAXIMUM LONG_MAX
# endif
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned
# endif
#endif

#define YYSIZE_MAXIMUM                                  \
  YY_CAST (YYPTRDIFF_T,                                 \
           (YYPTRDIFF_MAXIMUM < YY_CAST (YYSIZE_T, -1)  \
            ? YYPTRDIFF_MAXIMUM                         \
            : YY_CAST (YYSIZE_T, -1)))

#define YYSIZEOF(X) YY_CAST (YYPTRDIFF_T, sizeof (X))


/* Stored state numbers (used for stacks). */
typedef yytype_uint8 yy_state_t;

/* State numbers in computations.  */
typedef int yy_state_fast_t;

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(Msgid) dgettext ("bison-runtime", Msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(Msgid) Msgid
# endif
#endif


#ifndef YY_ATTRIBUTE_PURE
# if defined __GNUC__ && 2 < __GNUC__ + (96 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_PURE __attribute__ ((__pure__))
# else
#  define YY_ATTRIBUTE_PURE
# endif
#endif

#ifndef YY_ATTRIBUTE_UNUSED
# if defined __GNUC__ && 2 < __GNUC__ + (7 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_UNUSED __attribute__ ((__unused__))
# else
#  define YY_ATTRIBUTE_UNUSED
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YY_USE(E) ((void) (E))
#else
# define YY_USE(E) /* empty */
#endif

/* Suppress an incorrect diagnostic about yylval being uninitialized.  */
#if defined __GNUC__ && ! defined __ICC && 406 <= __GNUC__ * 100 + __GNUC_MINOR__
# if __GNUC__ * 100 + __GNUC_MINOR__ < 407
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")
# else
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")              \
    _Pragma ("GCC diagnostic ignored \"-Wmaybe-uninitialized\"")
# endif
# define YY_IGNORE_MAYBE_UNINITIALIZED_END      \
    _Pragma ("GCC diagnostic pop")
#else
# define YY_INITIAL_VALUE(Value) Value
#endif
#ifndef YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_END
#endif
#ifndef YY_INITIAL_VALUE
# define YY_INITIAL_VALUE(Value) /* Nothing. */
#endif

#if defined __cplusplus && defined __GNUC__ && ! defined __ICC && 6 <= __GNUC__
# define YY_IGNORE_USELESS_CAST_BEGIN                          \
    _Pragma ("GCC diagnostic push")                            \
    _Pragma ("GCC diagnostic ignored \"-Wuseless-cast\"")
# define YY_IGNORE_USELESS_CAST_END            \
    _Pragma ("GCC diagnostic pop")
#endif
#ifndef YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_END
#endif


#define YY_ASSERT(E) ((void) (0 && (E)))

#if !defined yyoverflow

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined EXIT_SUCCESS
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
      /* Use EXIT_SUCCESS as a witness for stdlib.h.  */
#     ifndef EXIT_SUCCESS
#      define EXIT_SUCCESS 0
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's 'empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined EXIT_SUCCESS \
       && ! ((defined YYMALLOC || defined malloc) \
             && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef EXIT_SUCCESS
#    define EXIT_SUCCESS 0
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined EXIT_SUCCESS
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined EXIT_SUCCESS
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* !defined yyoverflow */

#if (! defined yyoverflow \
     && (! defined __cplusplus \
         || (defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yy_state_t yyss_alloc;
  YYSTYPE yyvs_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (YYSIZEOF (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (YYSIZEOF (yy_state_t) + YYSIZEOF (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

# define YYCOPY_NEEDED 1

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)                           \
    do                                                                  \
      {                                                                 \
        YYPTRDIFF_T yynewbytes;                                         \
        YYCOPY (&yyptr->Stack_alloc, Stack, yysize);                    \
        Stack = &yyptr->Stack_alloc;                                    \
        yynewbytes = yystacksize * YYSIZEOF (*Stack) + YYSTACK_GAP_MAXIMUM; \
        yyptr += yynewbytes / YYSIZEOF (*yyptr);                        \
      }                                                                 \
    while (0)

#endif

#if defined YYCOPY_NEEDED && YYCOPY_NEEDED
/* Copy COUNT objects from SRC to DST.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(Dst, Src, Count) \
      __builtin_memcpy (Dst, Src, YY_CAST (YYSIZE_T, (Count)) * sizeof (*(Src)))
#  else
#   define YYCOPY(Dst, Src, Count)              \
      do                                        \
        {                                       \
          YYPTRDIFF_T yyi;                      \
          for (yyi = 0; yyi < (Count); yyi++)   \
            (Dst)[yyi] = (Src)[yyi];            \
        }                                       \
      while (0)
#  endif
# endif
#endif /* !YYCOPY_NEEDED */

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  6
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   228

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  55
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  54
/* YYNRULES -- Number of rules.  */
#define YYNRULES  122
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  213

/* YYMAXUTOK -- Last valid token kind.  */
#define YYMAXUTOK   309


/* YYTRANSLATE(TOKEN-NUM) -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex, with out-of-bounds checking.  */
#define YYTRANSLATE(YYX)                                \
  (0 <= (YYX) && (YYX) <= YYMAXUTOK                     \
   ? YY_CAST (yysymbol_kind_t, yytranslate[YYX])        \
   : YYSYMBOL_YYUNDEF)

/* YYTRANSLATE[TOKEN-NUM] -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex.  */
static const yytype_int8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54
};

#if YYDEBUG
/* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
static const yytype_int16 yyrline[] =
{
       0,   114,   114,   114,   118,   123,   125,   126,   127,   128,
     129,   130,   131,   132,   133,   134,   137,   139,   140,   141,
     142,   147,   154,   159,   166,   175,   177,   178,   179,   180,
     181,   184,   192,   198,   208,   214,   220,   226,   234,   239,
     246,   256,   261,   269,   272,   274,   275,   276,   277,   278,
     281,   287,   294,   300,   305,   313,   314,   315,   316,   319,
     320,   323,   324,   325,   329,   337,   345,   348,   353,   360,
     365,   373,   376,   378,   379,   382,   391,   398,   401,   403,
     408,   414,   427,   433,   433,   439,   446,   452,   452,   457,
     457,   463,   470,   477,   484,   486,   491,   492,   493,   496,
     497,   500,   501,   502,   503,   504,   505,   506,   507,   508,
     509,   510,   514,   516,   517,   520,   521,   525,   528,   529,
     530,   534,   535
};
#endif

/** Accessing symbol of state STATE.  */
#define YY_ACCESSING_SYMBOL(State) YY_CAST (yysymbol_kind_t, yystos[State])

#if YYDEBUG || 0
/* The user-facing name of the symbol whose (internal) number is
   YYSYMBOL.  No bounds checking.  */
static const char *yysymbol_name (yysymbol_kind_t yysymbol) YY_ATTRIBUTE_UNUSED;

/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "\"end of file\"", "error", "\"invalid token\"", "T_HELPTEXT", "T_WORD",
  "T_WORD_QUOTE", "T_BOOL", "T_CHOICE", "T_CLOSE_PAREN", "T_COLON_EQUAL",
  "T_COMMENT", "T_CONFIG", "T_DEFAULT", "T_DEF_BOOL", "T_DEF_TRISTATE",
  "T_DEPENDS", "T_ENDCHOICE", "T_ENDIF", "T_ENDMENU", "T_HELP", "T_DETAIL",
  "T_TOOLTIP", "T_HEX", "T_IF", "T_IMPLY", "T_INT", "T_MAINMENU", "T_MENU",
  "T_MENUCONFIG", "T_MODULES", "T_ON", "T_OPEN_PAREN", "T_OPTIONAL",
  "T_PLUS_EQUAL", "T_PROMPT", "T_RANGE", "T_RESET", "T_MAINTAINER",
  "T_LABEL", "T_SELECT", "T_SOURCE", "T_STRING", "T_TRISTATE", "T_VISIBLE",
  "T_EOL", "T_ASSIGN_VAL", "T_OR", "T_AND", "T_EQUAL", "T_UNEQUAL",
  "T_LESS", "T_LESS_EQUAL", "T_GREATER", "T_GREATER_EQUAL", "T_NOT",
  "$accept", "input", "mainmenu_stmt", "stmt_list", "stmt_list_in_choice",
  "config_entry_start", "config_stmt", "menuconfig_entry_start",
  "menuconfig_stmt", "config_option_list", "config_option", "choice",
  "choice_entry", "choice_end", "choice_stmt", "choice_option_list",
  "choice_option", "type", "logic_type", "default", "if_entry", "if_end",
  "if_stmt", "if_stmt_in_choice", "menu", "menu_entry", "menu_end",
  "menu_stmt", "menu_option_list", "source_stmt", "comment",
  "comment_stmt", "comment_option_list", "help_start", "help",
  "detail_start", "detail_cond", "detail", "tooltip_start", "tooltip_type",
  "tooltip_cond", "tooltip", "depends", "visible", "prompt_stmt_opt",
  "end", "if_expr", "expr", "nonconst_symbol", "symbol", "word_opt",
  "assignment_stmt", "assign_op", "assign_val", YY_NULLPTR
};

static const char *
yysymbol_name (yysymbol_kind_t yysymbol)
{
  return yytname[yysymbol];
}
#endif

#define YYPACT_NINF (-129)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-4)

#define yytable_value_is_error(Yyn) \
  0

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
static const yytype_int16 yypact[] =
{
     -18,    31,    42,  -129,    45,   -13,  -129,    88,    21,    18,
      55,    52,    79,    13,    82,    79,    85,  -129,  -129,  -129,
    -129,  -129,  -129,  -129,  -129,  -129,  -129,  -129,  -129,  -129,
    -129,  -129,  -129,  -129,  -129,    40,  -129,  -129,  -129,    60,
    -129,    57,    64,  -129,    65,  -129,    13,    13,   -24,  -129,
      29,    66,    68,    69,   152,   152,   186,    53,   129,   -11,
     129,    99,  -129,  -129,    73,  -129,  -129,  -129,     1,  -129,
    -129,    13,    13,    70,    70,    70,    70,    70,    70,  -129,
    -129,  -129,  -129,  -129,  -129,  -129,    89,    74,    97,   117,
    -129,    79,  -129,    78,   118,    70,   124,   126,    79,  -129,
    -129,  -129,   127,  -129,    13,   131,  -129,   132,  -129,   134,
    -129,  -129,    79,    98,   136,   120,  -129,   127,  -129,  -129,
    -129,  -129,   100,   104,   105,   106,  -129,  -129,  -129,  -129,
    -129,  -129,  -129,  -129,   120,  -129,  -129,  -129,  -129,  -129,
    -129,  -129,   107,  -129,  -129,  -129,  -129,  -129,  -129,  -129,
      13,  -129,    13,   109,  -129,   128,   120,  -129,   120,    70,
     111,   115,   120,   120,   116,    15,  -129,  -129,  -129,   120,
    -129,   120,    13,   119,   135,  -129,  -129,  -129,  -129,    53,
     138,    56,    -7,  -129,    13,   139,   140,   141,   120,  -129,
    -129,   144,  -129,  -129,   151,   153,   155,    -7,  -129,  -129,
    -129,  -129,  -129,    -7,  -129,  -129,  -129,   156,  -129,  -129,
    -129,  -129,  -129
};

/* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
   Performed when YYTABLE does not specify something else to do.  Zero
   means the default is an error.  */
static const yytype_int8 yydefact[] =
{
       5,     0,     0,     5,     0,     0,     1,     0,     0,     0,
     115,     0,     0,     0,     0,     0,     0,    25,     9,    25,
      12,    44,    16,     7,     5,    10,    72,     5,    11,    13,
      78,     8,     6,     4,    15,     0,   119,   120,   118,   121,
     116,     0,     0,   112,     0,   114,     0,     0,     0,   113,
     101,     0,     0,     0,    22,    24,    41,     0,     0,    69,
       0,    77,    14,   122,     0,    40,    76,    21,     0,   109,
      64,     0,     0,     0,     0,     0,     0,     0,     0,    68,
      23,    75,    59,    61,    62,    63,     0,     0,    83,    87,
      57,     0,    56,     0,     0,     0,     0,     0,     0,    58,
      60,    26,    94,    55,     0,     0,    28,     0,    29,     0,
      30,    27,     0,     0,     0,    99,    45,    94,    47,    48,
      49,    46,     0,     0,     0,     0,    18,    43,    16,    19,
      17,    42,    66,    65,    99,    74,    73,    71,    70,    79,
     117,   108,   110,   111,   106,   107,   102,   103,   104,   105,
       0,    80,     0,     0,    88,    89,    99,    37,    99,     0,
       0,     0,    99,    99,     0,    99,    81,    85,    91,    99,
      52,    99,     0,     0,     0,    20,    97,    98,    96,     0,
       0,     0,    84,    82,     0,     0,     0,     0,    99,    38,
      39,     0,    95,    31,     0,     0,     0,   100,    53,    51,
      67,    93,    92,    90,    86,    35,    32,     0,    34,    33,
      54,    50,    36
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -129,  -129,  -129,    26,    33,  -129,   -55,  -129,  -129,   143,
    -129,  -129,  -129,  -129,  -129,  -129,  -129,  -129,   112,  -129,
     -54,    -9,  -129,  -129,  -129,  -129,  -129,  -129,  -129,  -129,
    -129,   -52,  -129,  -129,   122,  -129,  -129,   146,  -129,  -129,
    -129,   147,    35,  -129,    58,   -36,  -128,   -46,    -5,   -62,
    -129,  -129,  -129,  -129
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_uint8 yydefgoto[] =
{
       0,     2,     3,     4,    57,    17,    18,    19,    20,    54,
     101,    21,    22,   127,    23,    56,   116,   102,   103,   104,
      24,   132,    25,   129,    26,    27,   137,    28,    59,    29,
      30,    31,    61,   105,   106,   107,   153,   108,   109,   155,
     185,   110,   111,   136,   164,   133,   173,    48,    49,    50,
      41,    32,    39,    64
};

/* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule whose
   number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_int16 yytable[] =
{
      68,    69,   126,   128,    86,   130,   180,    44,     1,   141,
      52,   144,   145,   146,   147,   148,   149,    43,    45,    35,
      70,   131,    71,    72,   138,   142,   143,    36,   186,     7,
     187,    33,   134,   159,   191,   192,     5,   194,   172,    71,
      72,   195,     6,   196,    46,    -3,     8,    71,    72,     9,
      58,    37,    10,    60,   122,    11,    12,    42,   165,    40,
     207,    71,    72,    11,    12,    34,    38,    47,    13,   123,
     124,   125,    14,    15,    43,    45,    13,    73,    74,    75,
      76,    77,    78,    43,    62,    16,   156,    51,    -2,     8,
      53,   121,     9,   162,   135,    10,   139,   188,    11,    12,
     202,    65,    71,    72,   181,    63,   182,   169,    66,    67,
      79,    13,    80,    81,    86,    14,    15,   140,   151,   150,
     152,   154,   157,   158,   126,   128,   197,   130,    16,   160,
       8,   161,   163,     9,   166,   167,    10,   168,   203,    11,
      12,   171,   170,   172,   175,   123,   124,   125,   176,   177,
     178,   184,    13,   183,    72,   189,    14,    15,    82,   190,
     193,   179,    55,   198,    83,    84,    85,    86,   117,    16,
     200,    87,    88,    89,    90,   174,    91,    92,   118,   199,
       0,    93,   201,   204,   205,   206,    94,    95,   208,    96,
      97,    98,    82,    99,   100,   209,     0,   210,   112,   211,
     212,    86,   119,   120,     0,    87,    88,    89,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,   113,     0,
     114,     0,   115,     0,     0,     0,     0,     0,   100
};

static const yytype_int16 yycheck[] =
{
      46,    47,    57,    57,    15,    57,   134,    12,    26,     8,
      15,    73,    74,    75,    76,    77,    78,     4,     5,     1,
      44,    57,    46,    47,    60,    71,    72,     9,   156,     3,
     158,    44,    43,    95,   162,   163,     5,   165,    23,    46,
      47,   169,     0,   171,    31,     0,     1,    46,    47,     4,
      24,    33,     7,    27,     1,    10,    11,     5,   104,     4,
     188,    46,    47,    10,    11,    44,    48,    54,    23,    16,
      17,    18,    27,    28,     4,     5,    23,    48,    49,    50,
      51,    52,    53,     4,    44,    40,    91,     5,     0,     1,
       5,    56,     4,    98,    59,     7,    61,   159,    10,    11,
      44,    44,    46,    47,   150,    45,   152,   112,    44,    44,
      44,    23,    44,    44,    15,    27,    28,    44,    44,    30,
      23,     4,    44,     5,   179,   179,   172,   179,    40,     5,
       1,     5,     5,     4,     3,     3,     7,     3,   184,    10,
      11,     5,    44,    23,    44,    16,    17,    18,    44,    44,
      44,    23,    23,    44,    47,    44,    27,    28,     6,    44,
      44,   128,    19,    44,    12,    13,    14,    15,    56,    40,
     179,    19,    20,    21,    22,   117,    24,    25,    56,    44,
      -1,    29,    44,    44,    44,    44,    34,    35,    44,    37,
      38,    39,     6,    41,    42,    44,    -1,    44,    12,    44,
      44,    15,    56,    56,    -1,    19,    20,    21,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    32,    -1,
      34,    -1,    36,    -1,    -1,    -1,    -1,    -1,    42
};

/* YYSTOS[STATE-NUM] -- The symbol kind of the accessing symbol of
   state STATE-NUM.  */
static const yytype_int8 yystos[] =
{
       0,    26,    56,    57,    58,     5,     0,    58,     1,     4,
       7,    10,    11,    23,    27,    28,    40,    60,    61,    62,
      63,    66,    67,    69,    75,    77,    79,    80,    82,    84,
      85,    86,   106,    44,    44,     1,     9,    33,    48,   107,
       4,   105,     5,     4,   103,     5,    31,    54,   102,   103,
     104,     5,   103,     5,    64,    64,    70,    59,    58,    83,
      58,    87,    44,    45,   108,    44,    44,    44,   102,   102,
      44,    46,    47,    48,    49,    50,    51,    52,    53,    44,
      44,    44,     6,    12,    13,    14,    15,    19,    20,    21,
      22,    24,    25,    29,    34,    35,    37,    38,    39,    41,
      42,    65,    72,    73,    74,    88,    89,    90,    92,    93,
      96,    97,    12,    32,    34,    36,    71,    73,    89,    92,
      96,    97,     1,    16,    17,    18,    61,    68,    75,    78,
      86,   100,    76,   100,    43,    97,    98,    81,   100,    97,
      44,     8,   102,   102,   104,   104,   104,   104,   104,   104,
      30,    44,    23,    91,     4,    94,   103,    44,     5,   104,
       5,     5,   103,     5,    99,   102,     3,     3,     3,   103,
      44,     5,    23,   101,    99,    44,    44,    44,    44,    59,
     101,   102,   102,    44,    23,    95,   101,   101,   104,    44,
      44,   101,   101,    44,   101,   101,   101,   102,    44,    44,
      76,    44,    44,   102,    44,    44,    44,   101,    44,    44,
      44,    44,    44
};

/* YYR1[RULE-NUM] -- Symbol kind of the left-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr1[] =
{
       0,    55,    56,    56,    57,    58,    58,    58,    58,    58,
      58,    58,    58,    58,    58,    58,    59,    59,    59,    59,
      59,    60,    61,    62,    63,    64,    64,    64,    64,    64,
      64,    65,    65,    65,    65,    65,    65,    65,    65,    65,
      66,    67,    68,    69,    70,    70,    70,    70,    70,    70,
      71,    71,    71,    71,    71,    72,    72,    72,    72,    73,
      73,    74,    74,    74,    75,    76,    77,    78,    79,    80,
      81,    82,    83,    83,    83,    84,    85,    86,    87,    87,
      88,    89,    90,    91,    91,    92,    93,    94,    94,    95,
      95,    96,    97,    98,    99,    99,   100,   100,   100,   101,
     101,   102,   102,   102,   102,   102,   102,   102,   102,   102,
     102,   102,   103,   104,   104,   105,   105,   106,   107,   107,
     107,   108,   108
};

/* YYR2[RULE-NUM] -- Number of symbols on the right-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr2[] =
{
       0,     2,     2,     1,     3,     0,     2,     2,     2,     2,
       2,     2,     2,     2,     4,     3,     0,     2,     2,     2,
       3,     3,     2,     3,     2,     0,     2,     2,     2,     2,
       2,     3,     4,     4,     4,     4,     5,     2,     3,     3,
       3,     2,     1,     3,     0,     2,     2,     2,     2,     2,
       4,     3,     2,     3,     4,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     3,     1,     3,     3,     3,     2,
       1,     3,     0,     2,     2,     3,     3,     2,     0,     2,
       2,     2,     3,     0,     2,     2,     4,     0,     1,     0,
       2,     2,     4,     3,     0,     2,     2,     2,     2,     0,
       2,     1,     3,     3,     3,     3,     3,     3,     3,     2,
       3,     3,     1,     1,     1,     0,     1,     4,     1,     1,
       1,     0,     1
};


enum { YYENOMEM = -2 };

#define yyerrok         (yyerrstatus = 0)
#define yyclearin       (yychar = YYEMPTY)

#define YYACCEPT        goto yyacceptlab
#define YYABORT         goto yyabortlab
#define YYERROR         goto yyerrorlab
#define YYNOMEM         goto yyexhaustedlab


#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)                                    \
  do                                                              \
    if (yychar == YYEMPTY)                                        \
      {                                                           \
        yychar = (Token);                                         \
        yylval = (Value);                                         \
        YYPOPSTACK (yylen);                                       \
        yystate = *yyssp;                                         \
        goto yybackup;                                            \
      }                                                           \
    else                                                          \
      {                                                           \
        yyerror (YY_("syntax error: cannot back up")); \
        YYERROR;                                                  \
      }                                                           \
  while (0)

/* Backward compatibility with an undocumented macro.
   Use YYerror or YYUNDEF. */
#define YYERRCODE YYUNDEF


/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)                        \
do {                                            \
  if (yydebug)                                  \
    YYFPRINTF Args;                             \
} while (0)




# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)                    \
do {                                                                      \
  if (yydebug)                                                            \
    {                                                                     \
      YYFPRINTF (stderr, "%s ", Title);                                   \
      yy_symbol_print (stderr,                                            \
                  Kind, Value); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*-----------------------------------.
| Print this symbol's value on YYO.  |
`-----------------------------------*/

static void
yy_symbol_value_print (FILE *yyo,
                       yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep)
{
  FILE *yyoutput = yyo;
  YY_USE (yyoutput);
  if (!yyvaluep)
    return;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/*---------------------------.
| Print this symbol on YYO.  |
`---------------------------*/

static void
yy_symbol_print (FILE *yyo,
                 yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep)
{
  YYFPRINTF (yyo, "%s %s (",
             yykind < YYNTOKENS ? "token" : "nterm", yysymbol_name (yykind));

  yy_symbol_value_print (yyo, yykind, yyvaluep);
  YYFPRINTF (yyo, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

static void
yy_stack_print (yy_state_t *yybottom, yy_state_t *yytop)
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)                            \
do {                                                            \
  if (yydebug)                                                  \
    yy_stack_print ((Bottom), (Top));                           \
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

static void
yy_reduce_print (yy_state_t *yyssp, YYSTYPE *yyvsp,
                 int yyrule)
{
  int yylno = yyrline[yyrule];
  int yynrhs = yyr2[yyrule];
  int yyi;
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %d):\n",
             yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr,
                       YY_ACCESSING_SYMBOL (+yyssp[yyi + 1 - yynrhs]),
                       &yyvsp[(yyi + 1) - (yynrhs)]);
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, Rule); \
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args) ((void) 0)
# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif






/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

static void
yydestruct (const char *yymsg,
            yysymbol_kind_t yykind, YYSTYPE *yyvaluep)
{
  YY_USE (yyvaluep);
  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yykind, yyvaluep, yylocationp);

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  switch (yykind)
    {
    case YYSYMBOL_choice_entry: /* choice_entry  */
            {
	fprintf(stderr, "%s:%d: missing end statement for this entry\n",
		((*yyvaluep).menu)->file->name, ((*yyvaluep).menu)->lineno);
	if (current_menu == ((*yyvaluep).menu))
		menu_end_menu();
}
        break;

    case YYSYMBOL_if_entry: /* if_entry  */
            {
	fprintf(stderr, "%s:%d: missing end statement for this entry\n",
		((*yyvaluep).menu)->file->name, ((*yyvaluep).menu)->lineno);
	if (current_menu == ((*yyvaluep).menu))
		menu_end_menu();
}
        break;

    case YYSYMBOL_menu_entry: /* menu_entry  */
            {
	fprintf(stderr, "%s:%d: missing end statement for this entry\n",
		((*yyvaluep).menu)->file->name, ((*yyvaluep).menu)->lineno);
	if (current_menu == ((*yyvaluep).menu))
		menu_end_menu();
}
        break;

      default:
        break;
    }
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/* Lookahead token kind.  */
int yychar;

/* The semantic value of the lookahead symbol.  */
YYSTYPE yylval;
/* Number of syntax errors so far.  */
int yynerrs;




/*----------.
| yyparse.  |
`----------*/

int
yyparse (void)
{
    yy_state_fast_t yystate = 0;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus = 0;

    /* Refer to the stacks through separate pointers, to allow yyoverflow
       to reallocate them elsewhere.  */

    /* Their size.  */
    YYPTRDIFF_T yystacksize = YYINITDEPTH;

    /* The state stack: array, bottom, top.  */
    yy_state_t yyssa[YYINITDEPTH];
    yy_state_t *yyss = yyssa;
    yy_state_t *yyssp = yyss;

    /* The semantic value stack: array, bottom, top.  */
    YYSTYPE yyvsa[YYINITDEPTH];
    YYSTYPE *yyvs = yyvsa;
    YYSTYPE *yyvsp = yyvs;

  int yyn;
  /* The return value of yyparse.  */
  int yyresult;
  /* Lookahead symbol kind.  */
  yysymbol_kind_t yytoken = YYSYMBOL_YYEMPTY;
  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;



#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N))

  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yychar = YYEMPTY; /* Cause a token to be read.  */

  goto yysetstate;


/*------------------------------------------------------------.
| yynewstate -- push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;


/*--------------------------------------------------------------------.
| yysetstate -- set current state (the top of the stack) to yystate.  |
`--------------------------------------------------------------------*/
yysetstate:
  YYDPRINTF ((stderr, "Entering state %d\n", yystate));
  YY_ASSERT (0 <= yystate && yystate < YYNSTATES);
  YY_IGNORE_USELESS_CAST_BEGIN
  *yyssp = YY_CAST (yy_state_t, yystate);
  YY_IGNORE_USELESS_CAST_END
  YY_STACK_PRINT (yyss, yyssp);

  if (yyss + yystacksize - 1 <= yyssp)
#if !defined yyoverflow && !defined YYSTACK_RELOCATE
    YYNOMEM;
#else
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYPTRDIFF_T yysize = yyssp - yyss + 1;

# if defined yyoverflow
      {
        /* Give user a chance to reallocate the stack.  Use copies of
           these so that the &'s don't force the real ones into
           memory.  */
        yy_state_t *yyss1 = yyss;
        YYSTYPE *yyvs1 = yyvs;

        /* Each stack pointer address is followed by the size of the
           data in use in that stack, in bytes.  This used to be a
           conditional around just the two extra args, but that might
           be undefined if yyoverflow is a macro.  */
        yyoverflow (YY_("memory exhausted"),
                    &yyss1, yysize * YYSIZEOF (*yyssp),
                    &yyvs1, yysize * YYSIZEOF (*yyvsp),
                    &yystacksize);
        yyss = yyss1;
        yyvs = yyvs1;
      }
# else /* defined YYSTACK_RELOCATE */
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
        YYNOMEM;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
        yystacksize = YYMAXDEPTH;

      {
        yy_state_t *yyss1 = yyss;
        union yyalloc *yyptr =
          YY_CAST (union yyalloc *,
                   YYSTACK_ALLOC (YY_CAST (YYSIZE_T, YYSTACK_BYTES (yystacksize))));
        if (! yyptr)
          YYNOMEM;
        YYSTACK_RELOCATE (yyss_alloc, yyss);
        YYSTACK_RELOCATE (yyvs_alloc, yyvs);
#  undef YYSTACK_RELOCATE
        if (yyss1 != yyssa)
          YYSTACK_FREE (yyss1);
      }
# endif

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;

      YY_IGNORE_USELESS_CAST_BEGIN
      YYDPRINTF ((stderr, "Stack size increased to %ld\n",
                  YY_CAST (long, yystacksize)));
      YY_IGNORE_USELESS_CAST_END

      if (yyss + yystacksize - 1 <= yyssp)
        YYABORT;
    }
#endif /* !defined yyoverflow && !defined YYSTACK_RELOCATE */


  if (yystate == YYFINAL)
    YYACCEPT;

  goto yybackup;


/*-----------.
| yybackup.  |
`-----------*/
yybackup:
  /* Do appropriate processing given the current state.  Read a
     lookahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to lookahead token.  */
  yyn = yypact[yystate];
  if (yypact_value_is_default (yyn))
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either empty, or end-of-input, or a valid lookahead.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token\n"));
      yychar = yylex ();
    }

  if (yychar <= YYEOF)
    {
      yychar = YYEOF;
      yytoken = YYSYMBOL_YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else if (yychar == YYerror)
    {
      /* The scanner already issued an error message, process directly
         to error recovery.  But do not keep the error token as
         lookahead, it is too special and may lead us to an endless
         loop in error recovery. */
      yychar = YYUNDEF;
      yytoken = YYSYMBOL_YYerror;
      goto yyerrlab1;
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yytable_value_is_error (yyn))
        goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the lookahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);
  yystate = yyn;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END

  /* Discard the shifted token.  */
  yychar = YYEMPTY;
  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     '$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
  case 4: /* mainmenu_stmt: T_MAINMENU T_WORD_QUOTE T_EOL  */
{
	menu_add_prompt(P_MENU, (yyvsp[-1].string), NULL);
}
    break;

  case 14: /* stmt_list: stmt_list T_WORD error T_EOL  */
                                        { zconf_error("unknown statement \"%s\"", (yyvsp[-2].string)); }
    break;

  case 15: /* stmt_list: stmt_list error T_EOL  */
                                        { zconf_error("invalid statement"); }
    break;

  case 20: /* stmt_list_in_choice: stmt_list_in_choice error T_EOL  */
                                                { zconf_error("invalid statement"); }
    break;

  case 21: /* config_entry_start: T_CONFIG nonconst_symbol T_EOL  */
{
	(yyvsp[-1].symbol)->flags |= SYMBOL_OPTIONAL;
	menu_add_entry((yyvsp[-1].symbol));
	printd(DEBUG_PARSE, "%s:%d:config %s\n", zconf_curname(), zconf_lineno(), (yyvsp[-1].symbol)->name);
}
    break;

  case 22: /* config_stmt: config_entry_start config_option_list  */
{
	printd(DEBUG_PARSE, "%s:%d:endconfig\n", zconf_curname(), zconf_lineno());
}
    break;

  case 23: /* menuconfig_entry_start: T_MENUCONFIG nonconst_symbol T_EOL  */
{
	(yyvsp[-1].symbol)->flags |= SYMBOL_OPTIONAL;
	menu_add_entry((yyvsp[-1].symbol));
	printd(DEBUG_PARSE, "%s:%d:menuconfig %s\n", zconf_curname(), zconf_lineno(), (yyvsp[-1].symbol)->name);
}
    break;

  case 24: /* menuconfig_stmt: menuconfig_entry_start config_option_list  */
{
	if (current_entry->prompt)
		current_entry->prompt->type = P_MENU;
	else
		zconfprint("warning: menuconfig statement without prompt");
	printd(DEBUG_PARSE, "%s:%d:endconfig\n", zconf_curname(), zconf_lineno());
}
    break;

  case 31: /* config_option: type prompt_stmt_opt T_EOL  */
{
	menu_set_type((yyvsp[-2].type));
	printd(DEBUG_PARSE, "%s:%d:type(%u)\n",
		zconf_curname(), zconf_lineno(),
		(yyvsp[-2].type));
}
    break;

  case 32: /* config_option: T_PROMPT T_WORD_QUOTE if_expr T_EOL  */
{
	menu_add_prompt(P_PROMPT, (yyvsp[-2].string), (yyvsp[-1].expr));
	printd(DEBUG_PARSE, "%s:%d:prompt\n", zconf_curname(), zconf_lineno());
}
    break;

  case 33: /* config_option: default expr if_expr T_EOL  */
{
	menu_add_expr(P_DEFAULT, (yyvsp[-2].expr), (yyvsp[-1].expr));
	if ((yyvsp[-3].type) != S_UNKNOWN)
		menu_set_type((yyvsp[-3].type));
	printd(DEBUG_PARSE, "%s:%d:default(%u)\n",
		zconf_curname(), zconf_lineno(),
		(yyvsp[-3].type));
}
    break;

  case 34: /* config_option: T_SELECT nonconst_symbol if_expr T_EOL  */
{
	menu_add_symbol(P_SELECT, (yyvsp[-2].symbol), (yyvsp[-1].expr));
	printd(DEBUG_PARSE, "%s:%d:select\n", zconf_curname(), zconf_lineno());
}
    break;

  case 35: /* config_option: T_IMPLY nonconst_symbol if_expr T_EOL  */
{
	menu_add_symbol(P_IMPLY, (yyvsp[-2].symbol), (yyvsp[-1].expr));
	printd(DEBUG_PARSE, "%s:%d:imply\n", zconf_curname(), zconf_lineno());
}
    break;

  case 36: /* config_option: T_RANGE symbol symbol if_expr T_EOL  */
{
	menu_add_expr(P_RANGE, expr_alloc_comp(E_RANGE,(yyvsp[-3].symbol), (yyvsp[-2].symbol)), (yyvsp[-1].expr));
	printd(DEBUG_PARSE, "%s:%d:range\n", zconf_curname(), zconf_lineno());
}
    break;

  case 37: /* config_option: T_MODULES T_EOL  */
{
	if (modules_sym)
		zconf_error("symbol '%s' redefines option 'modules' already defined by symbol '%s'",
			    current_entry->sym->name, modules_sym->name);
	modules_sym = current_entry->sym;
}
    break;

  case 38: /* config_option: T_MAINTAINER T_WORD_QUOTE T_EOL  */
{
	printd(DEBUG_PARSE, "%s:%d:maintainer(%s)\n", zconf_curname(), zconf_lineno(), (yyvsp[-1].string));
}
    break;

  case 39: /* config_option: T_LABEL T_WORD_QUOTE T_EOL  */
{
	printd(DEBUG_PARSE, "%s:%d:label(%s)\n", zconf_curname(), zconf_lineno(), (yyvsp[-1].string));
}
    break;

  case 40: /* choice: T_CHOICE word_opt T_EOL  */
{
	struct symbol *sym = sym_lookup((yyvsp[-1].string), SYMBOL_CHOICE);
	sym->flags |= SYMBOL_NO_WRITE;
	menu_add_entry(sym);
	menu_add_expr(P_CHOICE, NULL, NULL);
	free((yyvsp[-1].string));
	printd(DEBUG_PARSE, "%s:%d:choice\n", zconf_curname(), zconf_lineno());
}
    break;

  case 41: /* choice_entry: choice choice_option_list  */
{
	(yyval.menu) = menu_add_menu();
}
    break;

  case 42: /* choice_end: end  */
{
	if (zconf_endtoken((yyvsp[0].string), "choice")) {
		menu_end_menu();
		printd(DEBUG_PARSE, "%s:%d:endchoice\n", zconf_curname(), zconf_lineno());
	}
}
    break;

  case 50: /* choice_option: T_PROMPT T_WORD_QUOTE if_expr T_EOL  */
{
	menu_add_prompt(P_PROMPT, (yyvsp[-2].string), (yyvsp[-1].expr));
	printd(DEBUG_PARSE, "%s:%d:prompt\n", zconf_curname(), zconf_lineno());
}
    break;

  case 51: /* choice_option: logic_type prompt_stmt_opt T_EOL  */
{
	menu_set_type((yyvsp[-2].type));
	printd(DEBUG_PARSE, "%s:%d:type(%u)\n",
	       zconf_curname(), zconf_lineno(), (yyvsp[-2].type));
}
    break;

  case 52: /* choice_option: T_OPTIONAL T_EOL  */
{
	current_entry->sym->flags |= SYMBOL_OPTIONAL;
	printd(DEBUG_PARSE, "%s:%d:optional\n", zconf_curname(), zconf_lineno());
}
    break;

  case 53: /* choice_option: T_RESET if_expr T_EOL  */
{
	menu_add_prop(P_RESET, NULL, (yyvsp[-1].expr));
}
    break;

  case 54: /* choice_option: T_DEFAULT nonconst_symbol if_expr T_EOL  */
{
	menu_add_symbol(P_DEFAULT, (yyvsp[-2].symbol), (yyvsp[-1].expr));
	printd(DEBUG_PARSE, "%s:%d:default\n",
	       zconf_curname(), zconf_lineno());
}
    break;

  case 56: /* type: T_INT  */
                                { (yyval.type) = S_INT; }
    break;

  case 57: /* type: T_HEX  */
                                { (yyval.type) = S_HEX; }
    break;

  case 58: /* type: T_STRING  */
                                { (yyval.type) = S_STRING; }
    break;

  case 59: /* logic_type: T_BOOL  */
                                { (yyval.type) = S_BOOLEAN; }
    break;

  case 60: /* logic_type: T_TRISTATE  */
                                { (yyval.type) = S_TRISTATE; }
    break;

  case 61: /* default: T_DEFAULT  */
                                { (yyval.type) = S_UNKNOWN; }
    break;

  case 62: /* default: T_DEF_BOOL  */
                                { (yyval.type) = S_BOOLEAN; }
    break;

  case 63: /* default: T_DEF_TRISTATE  */
                                { (yyval.type) = S_TRISTATE; }
    break;

  case 64: /* if_entry: T_IF expr T_EOL  */
{
	printd(DEBUG_PARSE, "%s:%d:if\n", zconf_curname(), zconf_lineno());
	menu_add_entry(NULL);
	menu_add_dep((yyvsp[-1].expr));
	(yyval.menu) = menu_add_menu();
}
    break;

  case 65: /* if_end: end  */
{
	if (zconf_endtoken((yyvsp[0].string), "if")) {
		menu_end_menu();
		printd(DEBUG_PARSE, "%s:%d:endif\n", zconf_curname(), zconf_lineno());
	}
}
    break;

  case 68: /* menu: T_MENU T_WORD_QUOTE T_EOL  */
{
	menu_add_entry(NULL);
	menu_add_prompt(P_MENU, (yyvsp[-1].string), NULL);
	printd(DEBUG_PARSE, "%s:%d:menu\n", zconf_curname(), zconf_lineno());
}
    break;

  case 69: /* menu_entry: menu menu_option_list  */
{
	(yyval.menu) = menu_add_menu();
}
    break;

  case 70: /* menu_end: end  */
{
	if (zconf_endtoken((yyvsp[0].string), "menu")) {
		menu_end_menu();
		printd(DEBUG_PARSE, "%s:%d:endmenu\n", zconf_curname(), zconf_lineno());
	}
}
    break;

  case 75: /* source_stmt: T_SOURCE T_WORD_QUOTE T_EOL  */
{
	printd(DEBUG_PARSE, "%s:%d:source %s\n", zconf_curname(), zconf_lineno(), (yyvsp[-1].string));
	zconf_nextfile((yyvsp[-1].string));
	free((yyvsp[-1].string));
}
    break;

  case 76: /* comment: T_COMMENT T_WORD_QUOTE T_EOL  */
{
	menu_add_entry(NULL);
	menu_add_prompt(P_COMMENT, (yyvsp[-1].string), NULL);
	printd(DEBUG_PARSE, "%s:%d:comment\n", zconf_curname(), zconf_lineno());
}
    break;

  case 80: /* help_start: T_HELP T_EOL  */
{
	printd(DEBUG_PARSE, "%s:%d:help\n", zconf_curname(), zconf_lineno());
	zconf_starthelp();
}
    break;

  case 81: /* help: help_start T_HELPTEXT  */
{
	/* Is the help text empty or all whitespace? */
	if ((yyvsp[0].string)[strspn((yyvsp[0].string), " \f\n\r\t\v")] == '\0')
		zconfprint("warning: '%s' defined with blank help text",
			   current_entry->sym->name ?: "<choice>");

	printd(DEBUG_PARSE, "%s:%d:help(%s)\n", zconf_curname(), zconf_lineno(), (yyvsp[0].string));
	current_entry->help = (yyvsp[0].string);
}
    break;

  case 82: /* detail_start: T_DETAIL detail_cond T_EOL  */
{
	printd(DEBUG_PARSE, "%s:%d:detail\n", zconf_curname(), zconf_lineno());
	zconf_starthelp();
}
    break;

  case 84: /* detail_cond: T_IF expr  */
{
	printd(DEBUG_PARSE, "%s:%d:detail if\n", zconf_curname(), zconf_lineno());
	zconf_starthelp();
}
    break;

  case 85: /* detail: detail_start T_HELPTEXT  */
{
	printd(DEBUG_PARSE, "%s:%d:detail(%s)\n", zconf_curname(), zconf_lineno(), (yyvsp[0].string));
}
    break;

  case 86: /* tooltip_start: T_TOOLTIP tooltip_type tooltip_cond T_EOL  */
{
	printd(DEBUG_PARSE, "%s:%d:tooltip\n", zconf_curname(), zconf_lineno());
	zconf_starthelp();
}
    break;

  case 88: /* tooltip_type: T_WORD  */
{
	printd(DEBUG_PARSE, "%s:%d:tooltip type %s\n", zconf_curname(), zconf_lineno(), (yyvsp[0].string));
}
    break;

  case 90: /* tooltip_cond: T_IF expr  */
{
	printd(DEBUG_PARSE, "%s:%d:tooltip if\n", zconf_curname(), zconf_lineno());
	zconf_starthelp();
}
    break;

  case 91: /* tooltip: tooltip_start T_HELPTEXT  */
{
	printd(DEBUG_PARSE, "%s:%d:tooltip(%s)\n", zconf_curname(), zconf_lineno(), (yyvsp[0].string));
}
    break;

  case 92: /* depends: T_DEPENDS T_ON expr T_EOL  */
{
	menu_add_dep((yyvsp[-1].expr));
	printd(DEBUG_PARSE, "%s:%d:depends on\n", zconf_curname(), zconf_lineno());
}
    break;

  case 93: /* visible: T_VISIBLE if_expr T_EOL  */
{
	menu_add_visibility((yyvsp[-1].expr));
}
    break;

  case 95: /* prompt_stmt_opt: T_WORD_QUOTE if_expr  */
{
	menu_add_prompt(P_PROMPT, (yyvsp[-1].string), (yyvsp[0].expr));
}
    break;

  case 96: /* end: T_ENDMENU T_EOL  */
                                { (yyval.string) = "menu"; }
    break;

  case 97: /* end: T_ENDCHOICE T_EOL  */
                                { (yyval.string) = "choice"; }
    break;

  case 98: /* end: T_ENDIF T_EOL  */
                                { (yyval.string) = "if"; }
    break;

  case 99: /* if_expr: %empty  */
                                        { (yyval.expr) = NULL; }
    break;

  case 100: /* if_expr: T_IF expr  */
                                        { (yyval.expr) = (yyvsp[0].expr); }
    break;

  case 101: /* expr: symbol  */
                                                { (yyval.expr) = expr_alloc_symbol((yyvsp[0].symbol)); }
    break;

  case 102: /* expr: symbol T_LESS symbol  */
                                                { (yyval.expr) = expr_alloc_comp(E_LTH, (yyvsp[-2].symbol), (yyvsp[0].symbol)); }
    break;

  case 103: /* expr: symbol T_LESS_EQUAL symbol  */
                                                { (yyval.expr) = expr_alloc_comp(E_LEQ, (yyvsp[-2].symbol), (yyvsp[0].symbol)); }
    break;

  case 104: /* expr: symbol T_GREATER symbol  */
                                                { (yyval.expr) = expr_alloc_comp(E_GTH, (yyvsp[-2].symbol), (yyvsp[0].symbol)); }
    break;

  case 105: /* expr: symbol T_GREATER_EQUAL symbol  */
                                                { (yyval.expr) = expr_alloc_comp(E_GEQ, (yyvsp[-2].symbol), (yyvsp[0].symbol)); }
    break;

  case 106: /* expr: symbol T_EQUAL symbol  */
                                                { (yyval.expr) = expr_alloc_comp(E_EQUAL, (yyvsp[-2].symbol), (yyvsp[0].symbol)); }
    break;

  case 107: /* expr: symbol T_UNEQUAL symbol  */
                                                { (yyval.expr) = expr_alloc_comp(E_UNEQUAL, (yyvsp[-2].symbol), (yyvsp[0].symbol)); }
    break;

  case 108: /* expr: T_OPEN_PAREN expr T_CLOSE_PAREN  */
                                                { (yyval.expr) = (yyvsp[-1].expr); }
    break;

  case 109: /* expr: T_NOT expr  */
                                                { (yyval.expr) = expr_alloc_one(E_NOT, (yyvsp[0].expr)); }
    break;

  case 110: /* expr: expr T_OR expr  */
                                                { (yyval.expr) = expr_alloc_two(E_OR, (yyvsp[-2].expr), (yyvsp[0].expr)); }
    break;

  case 111: /* expr: expr T_AND expr  */
                                                { (yyval.expr) = expr_alloc_two(E_AND, (yyvsp[-2].expr), (yyvsp[0].expr)); }
    break;

  case 112: /* nonconst_symbol: T_WORD  */
                        { (yyval.symbol) = sym_lookup((yyvsp[0].string), 0); free((yyvsp[0].string)); }
    break;

  case 114: /* symbol: T_WORD_QUOTE  */
                        { (yyval.symbol) = sym_lookup((yyvsp[0].string), SYMBOL_CONST); free((yyvsp[0].string)); }
    break;

  case 115: /* word_opt: %empty  */
                                        { (yyval.string) = NULL; }
    break;

  case 117: /* assignment_stmt: T_WORD assign_op assign_val T_EOL  */
                                                        { variable_add((yyvsp[-3].string), (yyvsp[-1].string), (yyvsp[-2].flavor)); free((yyvsp[-3].string)); free((yyvsp[-1].string)); }
    break;

  case 118: /* assign_op: T_EQUAL  */
                        { (yyval.flavor) = VAR_RECURSIVE; }
    break;

  case 119: /* assign_op: T_COLON_EQUAL  */
                        { (yyval.flavor) = VAR_SIMPLE; }
    break;

  case 120: /* assign_op: T_PLUS_EQUAL  */
                        { (yyval.flavor) = VAR_APPEND; }
    break;

  case 121: /* assign_val: %empty  */
                                { (yyval.string) = xstrdup(""); }
    break;



      default: break;
    }
  /* User semantic actions sometimes alter yychar, and that requires
     that yytoken be updated with the new translation.  We take the
     approach of translating immediately before every use of yytoken.
     One alternative is translating here after every semantic action,
     but that translation would be missed if the semantic action invokes
     YYABORT, YYACCEPT, or YYERROR immediately after altering yychar or
     if it invokes YYBACKUP.  In the case of YYABORT or YYACCEPT, an
     incorrect destructor might then be invoked immediately.  In the
     case of YYERROR or YYBACKUP, subsequent parser actions might lead
     to an incorrect destructor call or verbose syntax error message
     before the lookahead is translated.  */
  YY_SYMBOL_PRINT ("-> $$ =", YY_CAST (yysymbol_kind_t, yyr1[yyn]), &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;

  *++yyvsp = yyval;

  /* Now 'shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */
  {
    const int yylhs = yyr1[yyn] - YYNTOKENS;
    const int yyi = yypgoto[yylhs] + *yyssp;
    yystate = (0 <= yyi && yyi <= YYLAST && yycheck[yyi] == *yyssp
               ? yytable[yyi]
               : yydefgoto[yylhs]);
  }

  goto yynewstate;


/*--------------------------------------.
| yyerrlab -- here on detecting error.  |
`--------------------------------------*/
yyerrlab:
  /* Make sure we have latest lookahead translation.  See comments at
     user semantic actions for why this is necessary.  */
  yytoken = yychar == YYEMPTY ? YYSYMBOL_YYEMPTY : YYTRANSLATE (yychar);
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
      yyerror (YY_("syntax error"));
    }

  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
         error, discard it.  */

      if (yychar <= YYEOF)
        {
          /* Return failure if at end of input.  */
          if (yychar == YYEOF)
            YYABORT;
        }
      else
        {
          yydestruct ("Error: discarding",
                      yytoken, &yylval);
          yychar = YYEMPTY;
        }
    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:
  /* Pacify compilers when the user code never invokes YYERROR and the
     label yyerrorlab therefore never appears in user code.  */
  if (0)
    YYERROR;
  ++yynerrs;

  /* Do not reclaim the symbols of the rule whose action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;      /* Each real token shifted decrements this.  */

  /* Pop stack until we find a state that shifts the error token.  */
  for (;;)
    {
      yyn = yypact[yystate];
      if (!yypact_value_is_default (yyn))
        {
          yyn += YYSYMBOL_YYerror;
          if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYSYMBOL_YYerror)
            {
              yyn = yytable[yyn];
              if (0 < yyn)
                break;
            }
        }

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
        YYABORT;


      yydestruct ("Error: popping",
                  YY_ACCESSING_SYMBOL (yystate), yyvsp);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END


  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", YY_ACCESSING_SYMBOL (yyn), yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturnlab;


/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturnlab;


/*-----------------------------------------------------------.
| yyexhaustedlab -- YYNOMEM (memory exhaustion) comes here.  |
`-----------------------------------------------------------*/
yyexhaustedlab:
  yyerror (YY_("memory exhausted"));
  yyresult = 2;
  goto yyreturnlab;


/*----------------------------------------------------------.
| yyreturnlab -- parsing is finished, clean up and return.  |
`----------------------------------------------------------*/
yyreturnlab:
  if (yychar != YYEMPTY)
    {
      /* Make sure we have latest lookahead translation.  See comments at
         user semantic actions for why this is necessary.  */
      yytoken = YYTRANSLATE (yychar);
      yydestruct ("Cleanup: discarding lookahead",
                  yytoken, &yylval);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
                  YY_ACCESSING_SYMBOL (+*yyssp), yyvsp);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif

  return yyresult;
}



void conf_parse(const char *name)
{
	struct symbol *sym;
	int i;

	zconf_initscan(name);

	_menu_init();

#if YYDEBUG
	if (getenv("ZCONF_DEBUG"))
		yydebug = 1;
#endif
	yyparse();

	/* Variables are expanded in the parse phase. We can free them here. */
	variable_all_del();

	if (yynerrs)
		exit(1);
	if (!modules_sym)
		modules_sym = sym_find( "n" );

	if (!menu_has_prompt(&rootmenu)) {
		current_entry = &rootmenu;
		menu_add_prompt(P_MENU, "Main menu", NULL);
	}

	menu_finalize(&rootmenu);
	for_all_symbols(i, sym) {
		if (sym_check_deps(sym))
			yynerrs++;
	}
	if (yynerrs)
		exit(1);
	conf_set_changed(true);
}

static bool zconf_endtoken(const char *tokenname,
			   const char *expected_tokenname)
{
	if (strcmp(tokenname, expected_tokenname)) {
		zconf_error("unexpected '%s' within %s block",
			    tokenname, expected_tokenname);
		yynerrs++;
		return false;
	}
	if (current_menu->file != current_file) {
		zconf_error("'%s' in different file than '%s'",
			    tokenname, expected_tokenname);
		fprintf(stderr, "%s:%d: location of the '%s'\n",
			current_menu->file->name, current_menu->lineno,
			expected_tokenname);
		yynerrs++;
		return false;
	}
	return true;
}

static void zconfprint(const char *err, ...)
{
	va_list ap;

	fprintf(stderr, "%s:%d: ", zconf_curname(), zconf_lineno());
	va_start(ap, err);
	vfprintf(stderr, err, ap);
	va_end(ap);
	fprintf(stderr, "\n");
}

static void zconf_error(const char *err, ...)
{
	va_list ap;

	yynerrs++;
	fprintf(stderr, "%s:%d: ", zconf_curname(), zconf_lineno());
	va_start(ap, err);
	vfprintf(stderr, err, ap);
	va_end(ap);
	fprintf(stderr, "\n");
}

static void yyerror(const char *err)
{
	fprintf(stderr, "%s:%d: %s\n", zconf_curname(), zconf_lineno() + 1, err);
}

static void print_quoted_string(FILE *out, const char *str)
{
	const char *p;
	int len;

	putc('"', out);
	while ((p = strchr(str, '"'))) {
		len = p - str;
		if (len)
			fprintf(out, "%.*s", len, str);
		fputs("\\\"", out);
		str = p + 1;
	}
	fputs(str, out);
	putc('"', out);
}

static void print_symbol(FILE *out, struct menu *menu)
{
	struct symbol *sym = menu->sym;
	struct property *prop;

	if (sym_is_choice(sym))
		fprintf(out, "\nchoice\n");
	else
		fprintf(out, "\nconfig %s\n", sym->name);
	switch (sym->type) {
	case S_BOOLEAN:
		fputs("  bool\n", out);
		break;
	case S_TRISTATE:
		fputs("  tristate\n", out);
		break;
	case S_STRING:
		fputs("  string\n", out);
		break;
	case S_INT:
		fputs("  integer\n", out);
		break;
	case S_HEX:
		fputs("  hex\n", out);
		break;
	default:
		fputs("  ???\n", out);
		break;
	}
	for (prop = sym->prop; prop; prop = prop->next) {
		if (prop->menu != menu)
			continue;
		switch (prop->type) {
		case P_PROMPT:
			fputs("  prompt ", out);
			print_quoted_string(out, prop->text);
			if (!expr_is_yes(prop->visible.expr)) {
				fputs(" if ", out);
				expr_fprint(prop->visible.expr, out);
			}
			fputc('\n', out);
			break;
		case P_DEFAULT:
			fputs( "  default ", out);
			expr_fprint(prop->expr, out);
			if (!expr_is_yes(prop->visible.expr)) {
				fputs(" if ", out);
				expr_fprint(prop->visible.expr, out);
			}
			fputc('\n', out);
			break;
		case P_CHOICE:
			fputs("  #choice value\n", out);
			break;
		case P_SELECT:
			fputs( "  select ", out);
			expr_fprint(prop->expr, out);
			fputc('\n', out);
			break;
		case P_IMPLY:
			fputs( "  imply ", out);
			expr_fprint(prop->expr, out);
			fputc('\n', out);
			break;
		case P_RANGE:
			fputs( "  range ", out);
			expr_fprint(prop->expr, out);
			fputc('\n', out);
			break;
		case P_MENU:
			fputs( "  menu ", out);
			print_quoted_string(out, prop->text);
			fputc('\n', out);
			break;
		case P_SYMBOL:
			fputs( "  symbol ", out);
			fprintf(out, "%s\n", prop->menu->sym->name);
			break;
		default:
			fprintf(out, "  unknown prop %d!\n", prop->type);
			break;
		}
	}
	if (menu->help) {
		int len = strlen(menu->help);
		while (menu->help[--len] == '\n')
			menu->help[len] = 0;
		fprintf(out, "  help\n%s\n", menu->help);
	}
}

void zconfdump(FILE *out)
{
	struct property *prop;
	struct symbol *sym;
	struct menu *menu;

	menu = rootmenu.list;
	while (menu) {
		if ((sym = menu->sym))
			print_symbol(out, menu);
		else if ((prop = menu->prompt)) {
			switch (prop->type) {
			case P_COMMENT:
				fputs("\ncomment ", out);
				print_quoted_string(out, prop->text);
				fputs("\n", out);
				break;
			case P_MENU:
				fputs("\nmenu ", out);
				print_quoted_string(out, prop->text);
				fputs("\n", out);
				break;
			default:
				;
			}
			if (!expr_is_yes(prop->visible.expr)) {
				fputs("  depends ", out);
				expr_fprint(prop->visible.expr, out);
				fputc('\n', out);
			}
		}

		if (menu->list)
			menu = menu->list;
		else if (menu->next)
			menu = menu->next;
		else while ((menu = menu->parent)) {
			if (menu->prompt && menu->prompt->type == P_MENU)
				fputs("\nendmenu\n", out);
			if (menu->next) {
				menu = menu->next;
				break;
			}
		}
	}
}
