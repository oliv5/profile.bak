macro InserLog(type) {
  hbuf = GetCurrentBuf()
  ln = GetBufLnCur(hbuf)
  txt = cat("MYTEXT, ", type)
  InsBufLine(hbuf, ln, txt)
}

macro InserLog2() {
  InserLog("YOURTEXT, ")
}

