#ifndef PMCPEPXMLWRITER_H
#define PMCPEPXMLWRITER_H

#include "carp.h"
#include "Peptide.h"
#include "PeptideMatch.h"
#include "PepXMLWriter.h"
#include "Protein.h"
#include "ProteinMatch.h"
#include "ProteinMatchCollection.h"
#include "PSMWriter.h"
#include "Spectrum.h"
#include "SpectrumMatch.h"

using namespace std;

class PMCPepXMLWriter : public PepXMLWriter, public PSMWriter {

 public:

  void openFile(
    string filename,
    bool overwrite
  );

  void openFile(
    CruxApplication* application,
    string filename,
    MATCH_FILE_TYPE type
  );

  void write(
    MatchCollection* collection,
    string database
  );

  void closeFile();

  /**
   * Writes the data in a ProteinMatchCollection to the currently open file
   */
  void write(
    ProteinMatchCollection* collection ///< collection to be written
  );

 protected:

  /**
   * Writes the PSMs in a ProteinMatchCollection to the currently open file
   */
  void writePSMs(
    ProteinMatchCollection* collection ///< collection to be written
  );

};

#endif // PMCPEPXMLWRITER_H

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 2
 * End:
 */

