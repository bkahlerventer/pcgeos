COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		DocView (Sample PC GEOS application)
FILE:		docview.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	7/91		Initial version

DESCRIPTION:
	This file source code for the DocView application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

IMPORTANT NOTE:
	This sample application is primarily intended to demonstrate a
	model for handling documents.  Basic parts of a PC/GEOS application
	are not documented heavily here.  See the "Hello" sample application
	for more detailed documentation on the standard parts of a PC/GEOS
	application.

RCS STAMP:
	$Id: docview.asm,v 1.1 97/04/04 16:33:01 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include vm.def

include object.def
include graphics.def

include Objects/winC.def

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib ui.def

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

DVProcessClass	class	GenProcessClass

;define messages for this class here.

DVProcessClass	endc

idata	segment
	DVProcessClass	mask CLASSF_NEVER_SAVED
idata	ends

;----------------------

; DVDocument class is our subclass of GenDocument that we use to add
; behavior to the GenDocument

DVDocumentClass	class	GenDocumentClass

DVDocumentClass endc

idata	segment
	DVDocumentClass
idata	ends

;------------------------------------------------------------------------------
;			Constants and structures
;------------------------------------------------------------------------------

DOCUMENT_PROTOCOL_MAJOR	=	1
DOCUMENT_PROTOCOL_MINOR	=	0

DOCUMENT_WIDTH		=	20*72
DOCUMENT_HEIGHT		=	20*72

OBJECT_BACKGROUND_COLOR	=	C_WHITE

INITIAL_X_POS		= 20
INITIAL_Y_POS		= 20

BOX_WIDTH		= 10
BOX_HEIGHT		= 10

; This is the structure of a datafile.  It is incredibly simple, storing just
; a x,y position

DVMapBlock	struct
    DVMB_xPos	word
    DVMB_yPos	word
DVMapBlock	ends

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

idata	ends

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		docview.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;		Code for DVProcessClass
;------------------------------------------------------------------------------

CommonCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	DVDocumentRecalcSize -- MSG_VIS_RECALC_SIZE for DVDocumentClass

DESCRIPTION:	Calculate and return our size

PASS:
	*ds:si - instance data
	es - segment of DVDocumentClass

	ax - The message

	cx - RecalcSizeArgs
	dx - RecalcSizeArgs

RETURN:
	cx - width
	dx - height

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/25/91		Initial version

------------------------------------------------------------------------------@
DVDocumentRecalcSize	method dynamic	DVDocumentClass, MSG_VIS_RECALC_SIZE
	mov	cx, DOCUMENT_WIDTH
	mov	dx, DOCUMENT_HEIGHT
	ret

DVDocumentRecalcSize	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	DVDocumentInitializeDocumentFile --
		MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE for DVDocumentClass

DESCRIPTION:	Initialize the document file (newly created).

PASS:
	*ds:si - instance data
	es - segment of DVDocumentClass

	ax - The message

	cx:dx - optr of document
	bp - file handle

RETURN:
	carry - set if error

DESTROYED:
	bx, si, di, ds, es (message handler)

PSEUDO CODE/STRATEGY:

	This message is invoked when a new document has been created and
	the document file needs to be initialized.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
DVDocumentInitializeDocumentFile	method dynamic	DVDocumentClass,
				MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE

	; Handle this message by creating our version of an empty
	; document, which is a map block with the DVMapBlock structure
	; in it and initialized to default values.

	mov	bx, ds:[di].GDI_fileHandle

	; Allocate a VM block (making it the size of the structure
	; that we want to save in it) and set that block to be the
	; map block

	; allocate a block, make it the map block and initialize it

	mov	cx, size DVMapBlock
	call	VMAlloc				;ax = VM block handle
	call	VMSetMapBlock			;make this the map block

	; Lock the newly created block so that we can use it.  Since we
	; are modifying the contents of the block it is essential that we
	; call VMDirty to let the VM code know that the block is modified.

	call	VMLock				;ax = segment, bp = handle
	call	VMDirty				;we're changing the block...
	mov	ds, ax				;ds = block
	mov	ds:DVMB_xPos, INITIAL_X_POS
	mov	ds:DVMB_yPos, INITIAL_Y_POS

	call	VMUnlock

	clc			;no error
	ret

DVDocumentInitializeDocumentFile	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	DVDocumentDraw -- MSG_VIS_DRAW for DVDocumentClass

DESCRIPTION:	Draw ourselves

PASS:
	*ds:si - instance data
	es - segment of DVDocumentClass

	ax - The message

	cl - DrawFlags
	bp - gstate

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/25/91		Initial version

------------------------------------------------------------------------------@
DVDocumentDraw	method dynamic	DVDocumentClass, MSG_VIS_DRAW

	push	ds:[di].GDI_fileHandle		;save file handle

	mov	di, bp				;di = gstate

	; if we were not called as the result of a MSG_META_EXPOSED, then we need
	; to clear the object first

	test	cl, mask DF_EXPOSED
	jnz	noClear
	mov	ax, OBJECT_BACKGROUND_COLOR
	call	GrSetAreaColor
	call	VisGetBounds
	call	GrFillRect
noClear:

	mov	ax, C_LIGHT_BLUE
	call	GrSetAreaColor

	; get position from data file

	pop	bx				;bx = file handle
	call	VMGetMapBlock
	call	VMLock
	mov	ds, ax				;ds = map block
	mov	ax, ds:DVMB_xPos
	mov	bx, ds:DVMB_yPos
	mov	cx, ax
	mov	dx, bx

	; center rectangle around the point

	sub	ax, BOX_WIDTH/2
	sub	bx, BOX_HEIGHT/2
	add	cx, BOX_WIDTH/2
	add	dx, BOX_HEIGHT/2
	call	GrFillRect

	call	VMUnlock

	ret

DVDocumentDraw	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	DVDocumentStartSelect -- MSG_META_START_SELECT for DVDocumentClass

DESCRIPTION:	Handle click in object

PASS:
	*ds:si - instance data
	es - segment of DVDocumentClass

	ax - The message

	cx - x position
	dx - y position
	bp - UIFunctionsActive

RETURN:
	ax - MouseReturnFlags

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
DVDocumentStartSelect	method dynamic	DVDocumentClass, MSG_META_START_SELECT

	mov	bx, ds:[di].GDI_fileHandle

	push	ds
	call	VMGetMapBlock
	call	VMLock
	call	VMDirty
	mov	ds, ax				;ds = map block
	mov	ds:DVMB_xPos, cx
	mov	ds:DVMB_yPos, dx

	call	VMUnlock
	pop	ds

	mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT
	call	ObjCallInstanceNoLock

	mov	ax, mask MRF_PROCESSED
	ret

DVDocumentStartSelect	endm

CommonCode	ends		;end of CommonCode resource
