#include <stdio.h>
#include <stdlib.h>
#include "libadalang.h"

#include "langkit_text.h"


static void
error(const char *msg)
{
    fputs(msg, stderr);
    exit(1);
}

int
main(void)
{
    ada_analysis_context ctx;
    ada_analysis_unit unit;
    unsigned n;
    ada_diagnostic diag;

    libadalang_initialize();
    ctx = ada_create_analysis_context("iso-8859-1", NULL);
    if (ctx == NULL)
        error("Could not create the analysis context");

    unit = ada_get_analysis_unit_from_file(ctx, "foo.adb", NULL, 0, 0);
    if (unit == NULL)
        error("Creating an analysis unit from foo.adb (a source with syntax"
              " errors) did not work");

    for (n = 0; n < ada_unit_diagnostic_count(unit); ++n)
      {
	if (!ada_unit_diagnostic(unit, n, &diag))
	  error("Could not retrieve a diagnostic");
	printf("Diagnostic: %u:%u-%u:%u: ",
	       diag.sloc_range.start.line,
	       diag.sloc_range.start.column,
	       diag.sloc_range.end.line,
	       diag.sloc_range.end.column);
	fprint_text(stdout, diag.message, false);
	putchar('\n');
      }

    ada_destroy_analysis_context(ctx);
    puts("Done.");
    return 0;
}
