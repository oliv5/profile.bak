macro InsertLine(txt, ln) {
  hbuf = GetCurrentBuf()
  if ln == ")" ln = GetBufLnCur(hbuf)
  InsBufLine(hbuf, ln, txt)
  SetBufIns(hbuf, ln+1, 0)
}

macro AppendTxt(txt, ln) {
  hbuf = GetCurrentBuf()
  if "@ln@" == ")" ln = GetBufLnCur(hbuf)
  line = GetBufLine(hbuf, ln)
  txt = cat(line, txt)
  putBufLine(hbuf, ln, txt)
}

macro DoxygenFile() {
  InsertLine("/**")
  InsertLine(" * \file ")
  InsertLine(" * \brief ")
  InsertLine(" * \author ")
  InsertLine(" * \version ")
  InsertLine(" * \date ")
  InsertLine(" * ")
  InsertLine(" * Comment... ")
  InsertLine(" */")
}

macro DoxygenFct() {
  InsertLine("/**")
  InsertLine(" * \fn ")
  InsertLine(" * \brief ")
  InsertLine(" * \param[in] ")
  InsertLine(" * \param[out] ")
  InsertLine(" * \return Nothing")
  InsertLine(" * \note ")
  InsertLine(" */")
}

macro DoxygenVar() {
  InsertLine("/**")
  InsertLine(" * \class/struct/union/enum/var ")
  InsertLine(" * \brief ")
  InsertLine(" * \note ")
  InsertLine(" */")
}

macro DoxygenField() {
  AppendTxt(" /*!< ... */")
}
