#ifdef GAUSSASM_EXPORTS
#define GAUSSASM_API __declspec(dllexport)
#else
#define GAUSSASM_API __declspec(dllimport)
#endif

extern GAUSSASM_API int nGaussASM;

GAUSSASM_API int fnGaussASM(void);
