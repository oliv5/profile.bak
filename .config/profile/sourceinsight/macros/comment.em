//
// Main comment/uncomment macro
//
macro Comment() {
	if (!UnCommentBlock()) {
		CommentBlock();
	}
}

//
// Comment the selected block of text using single line comments and indent it
//
macro CommentBlock() {
	commentStr = "//";
	commentLen = 2;

	hbuf = GetCurrentBuf();
	hwnd = GetCurrentWnd();

	sel = GetWndSel(hwnd);
	iLine = sel.lnFirst;
	
	// Add the comment string
	while (iLine <= sel.lnLast) {
		szLine = GetBufLine(hbuf, iLine);
		szLine = cat(commentStr, szLine);
		PutBufLine(hbuf, iLine, szLine);
		iLine = iLine + 1;
	}

	// Update selection
	if (sel.lnFirst == sel.lnLast) {
		sel.ichFirst = sel.ichFirst + 2*commentLen;
		sel.ichLim = sel.ichLim + 2*commentLen;
	}
	SetWndSel(hwnd, sel);

	return True;
}

//
// Undo the CommentBlock for the selected text.
//
macro UnCommentBlock() {
	done = False;

	commentStr = "//";
	commentLen = 2;

	hbuf = GetCurrentBuf();
	hwnd = GetCurrentWnd();

	sel = GetWndSel(hwnd);
	iLine = sel.lnFirst;

	// Look for and remove the comment string
	while (iLine <= sel.lnLast) {
		szLine = GetBufLine(hbuf, iLine);
		len = strlen(szLine);
		if (len >= commentLen) {
			if (_strcmp(szLine, commentStr)) {
				szNewLine = strmid(szLine, commentLen, strlen(szLine));	
				PutBufLine(hbuf, iLine, szNewLine);
				done = True;
			}
		}
		iLine = iLine + 1;
	}

	// Update selection
	if (sel.lnFirst == sel.lnLast) {
		sel.ichFirst = sel.ichFirst - commentLen;
		sel.ichLim = sel.ichLim - commentLen;
	}
	SetWndSel(hwnd, sel);

	return done;
}

//
// Min value
//
macro _min(a,b) {
	if (a<=b) { return a;} else { return b; }
}

//
// Compare 2 strings
//
macro _strcmp(a,b) {
	i = 0;
	len = _min(strlen(a), strlen(b));
	while(i < len) {
		if a[i]!=b[i]
			return False;
		i = i + 1;
	}
	return True;
}

