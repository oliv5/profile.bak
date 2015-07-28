macro InserLog(type) {
  global logId
  if logId == nil logId = 1

  // Prepare the text
  if type == nil type = "NOTEST"
  txt = cat("MYTEST + ", type)

  // Increment the logId
  logId++

  // Insert the lines
  hbuf = GetCurrentBuf()
  ln = GetBufLnCur(hbuf)
  InsBufLine(hbuf, ln, txt)
}

macro InserLogTest() {
  InserLog("YOURTEST, ")
}

