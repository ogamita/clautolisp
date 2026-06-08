/* clal_dwg.c — a thin in-process bridge between clautolisp and the
 * vendored GNU libredwg (clautolisp/third-party/libredwg), Phase 17e.
 *
 * Rather than bind libredwg's large Dwg_Data object model in CFFI, we
 * expose two trivial (int, path, path) entry points that do the
 * DWG<->DXF conversion in C — where the Bit_Chain / Dwg_Data struct
 * layouts are known from libredwg's own headers — and let the Lisp
 * side use its Phase-17c DXF codec as the interchange. This keeps the
 * CFFI surface tiny and robust across libredwg releases, stays
 * in-process (no subprocess), and links our self-built libredwg.
 *
 * clal_dwg_to_dxf: read a DWG, emit DXF (libredwg's writer).
 * clal_dxf_to_dwg: read a DXF, emit a DWG (libredwg's writer).
 *
 * Return value: libredwg's error code (0 = success; >=
 * DWG_ERR_CRITICAL means the conversion failed). -1 on a file-open
 * failure in the shim itself.
 */

#include <stdio.h>
#include <string.h>
#include "dwg.h"
#include "../../third-party/libredwg/src/bits.h"   /* Bit_Chain */

/* dwg_write_dxf is exported by libredwg but declared in the private
 * src/out_dxf.h; declare it here to avoid pulling that header in. */
extern int dwg_write_dxf (Bit_Chain *dat, Dwg_Data *dwg);

int
clal_dwg_to_dxf (const char *dwg_path, const char *dxf_path)
{
  Dwg_Data dwg;
  Bit_Chain dat;
  int error;

  memset (&dwg, 0, sizeof (dwg));
  memset (&dat, 0, sizeof (dat));

  error = dwg_read_file (dwg_path, &dwg);
  if (error >= DWG_ERR_CRITICAL)
    {
      dwg_free (&dwg);
      return error;
    }

  dat.version = dwg.header.version;
  dat.from_version = dwg.header.from_version;
  dat.opts = dwg.opts;
  dat.fh = fopen (dxf_path, "wb");
  if (!dat.fh)
    {
      dwg_free (&dwg);
      return -1;
    }

  error = dwg_write_dxf (&dat, &dwg);

  fclose (dat.fh);
  dwg_free (&dwg);
  return error;
}

int
clal_dxf_to_dwg (const char *dxf_path, const char *dwg_path)
{
  Dwg_Data dwg;
  int error;

  memset (&dwg, 0, sizeof (dwg));

  error = dxf_read_file (dxf_path, &dwg);
  if (error >= DWG_ERR_CRITICAL)
    {
      dwg_free (&dwg);
      return error;
    }

  error = dwg_write_file (dwg_path, &dwg);

  dwg_free (&dwg);
  return error;
}
