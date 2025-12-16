/**
 * WokeLang C API
 *
 * This header provides the C-compatible interface for WokeLang.
 * It can be used from C, C++, Zig, or any language supporting the C ABI.
 *
 * Example usage:
 *
 *     #include "wokelang.h"
 *
 *     int main() {
 *         WokeInterpreter* interp = woke_interpreter_new();
 *         if (!interp) return 1;
 *
 *         const char* code =
 *             "to greet(name: String) -> String {\n"
 *             "    give back \"Hello, \" + name + \"!\";\n"
 *             "}\n";
 *
 *         WokeResult result = woke_exec(interp, code);
 *         if (result != WOKE_OK) {
 *             printf("Error: %d\n", result);
 *         }
 *
 *         woke_interpreter_free(interp);
 *         return 0;
 *     }
 */

#ifndef WOKELANG_H
#define WOKELANG_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Opaque types */
typedef struct WokeInterpreter WokeInterpreter;
typedef struct WokeValue WokeValue;

/* Result codes */
typedef enum WokeResult {
    WOKE_OK = 0,
    WOKE_ERROR = 1,
    WOKE_PARSE_ERROR = 2,
    WOKE_RUNTIME_ERROR = 3,
    WOKE_NULL_POINTER = 4
} WokeResult;

/* Value type tags */
typedef enum WokeValueType {
    WOKE_TYPE_INT = 0,
    WOKE_TYPE_FLOAT = 1,
    WOKE_TYPE_STRING = 2,
    WOKE_TYPE_BOOL = 3,
    WOKE_TYPE_ARRAY = 4,
    WOKE_TYPE_UNIT = 5
} WokeValueType;

/* === Interpreter lifecycle === */

/**
 * Create a new WokeLang interpreter.
 *
 * @return Pointer to the interpreter, or NULL on failure.
 *         The caller is responsible for freeing with woke_interpreter_free.
 */
WokeInterpreter* woke_interpreter_new(void);

/**
 * Free a WokeLang interpreter.
 *
 * @param interp The interpreter to free. May be NULL (no-op).
 */
void woke_interpreter_free(WokeInterpreter* interp);

/**
 * Execute WokeLang source code.
 *
 * @param interp The interpreter instance.
 * @param source Null-terminated WokeLang source code.
 * @return WOKE_OK on success, error code otherwise.
 */
WokeResult woke_exec(WokeInterpreter* interp, const char* source);

/**
 * Evaluate an expression and get the result.
 *
 * @param interp The interpreter instance.
 * @param source Null-terminated expression to evaluate.
 * @param out_value Pointer to receive the result value.
 * @return WOKE_OK on success, error code otherwise.
 */
WokeResult woke_eval(WokeInterpreter* interp, const char* source, WokeValue** out_value);

/* === Value operations === */

/**
 * Free a WokeValue.
 *
 * @param value The value to free. May be NULL (no-op).
 */
void woke_value_free(WokeValue* value);

/**
 * Get the type of a WokeValue.
 *
 * @param value The value to inspect.
 * @return The type tag.
 */
WokeValueType woke_value_type(const WokeValue* value);

/**
 * Get an integer from a WokeValue.
 *
 * @param value The value to read.
 * @param out Pointer to receive the integer.
 * @return WOKE_OK on success, WOKE_ERROR if type mismatch.
 */
WokeResult woke_value_as_int(const WokeValue* value, int64_t* out);

/**
 * Get a float from a WokeValue.
 *
 * @param value The value to read.
 * @param out Pointer to receive the float.
 * @return WOKE_OK on success, WOKE_ERROR if type mismatch.
 */
WokeResult woke_value_as_float(const WokeValue* value, double* out);

/**
 * Get a boolean from a WokeValue.
 *
 * @param value The value to read.
 * @param out Pointer to receive the boolean (0 or 1).
 * @return WOKE_OK on success, WOKE_ERROR if type mismatch.
 */
WokeResult woke_value_as_bool(const WokeValue* value, int* out);

/**
 * Get a string from a WokeValue.
 *
 * @param value The value to read.
 * @return Newly allocated string, or NULL on error.
 *         Caller must free with woke_string_free.
 */
char* woke_value_as_string(const WokeValue* value);

/**
 * Free a string returned by woke_value_as_string.
 *
 * @param s The string to free. May be NULL (no-op).
 */
void woke_string_free(char* s);

/* === Value creation === */

/**
 * Create an integer WokeValue.
 *
 * @param n The integer value.
 * @return New value, or NULL on allocation failure.
 */
WokeValue* woke_value_from_int(int64_t n);

/**
 * Create a float WokeValue.
 *
 * @param f The float value.
 * @return New value, or NULL on allocation failure.
 */
WokeValue* woke_value_from_float(double f);

/**
 * Create a boolean WokeValue.
 *
 * @param b The boolean value (0 = false, nonzero = true).
 * @return New value, or NULL on allocation failure.
 */
WokeValue* woke_value_from_bool(int b);

/**
 * Create a string WokeValue.
 *
 * @param s Null-terminated string to copy.
 * @return New value, or NULL on allocation failure.
 */
WokeValue* woke_value_from_string(const char* s);

/* === Utility === */

/**
 * Get the WokeLang version string.
 *
 * @return Static version string (do not free).
 */
const char* woke_version(void);

/**
 * Get the last error message.
 *
 * @return Error message, or NULL if no error.
 *         Valid until the next woke_* call.
 */
const char* woke_last_error(void);

#ifdef __cplusplus
}
#endif

#endif /* WOKELANG_H */
