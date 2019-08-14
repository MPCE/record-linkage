# MPCE Record Linkage

*Mapping Print, Charting Enlightenment* is the latest phase in a long-running French book history project. One aim of this phase of the project is to integrate a range of new datasets with the original database, which contained the records of the Soci&eacute;t&eacute; Typographique de Neuch&acirc;tel.

This repository contains a series of R scripts and iPython notebooks that use a machine learning approach to join some of these new datasets with the original database.

The `init.R` file contains some functions that can be used to easily perform fuzzy string matching on structured data. The `dedupe_helper_functions.py` file creates a basic functional programming interface for the [dedupe](https://github.com/dedupeio/dedupe) library.

## Contributors:

* **Michael Falk**: Developer and Research Project Manager, Digital Humanities Research Group, Western Sydney University

## Licence:

MIT. Please see the licence file included in this repo.