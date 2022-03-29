unit Main;

interface

// ? Imports
uses
	System.Math,
	System.UITypes,
	System.Generics.Collections,
	Winapi.Windows,
	Winapi.Messages,
	System.SysUtils,
	System.Variants,
	System.Classes,
	Vcl.Graphics,
	Vcl.Controls,
	Vcl.Forms,
	Vcl.Dialogs,
	Vcl.StdCtrls,
	Vcl.ExtCtrls,
	Vcl.Imaging.pngimage;

// ? Objects Definitions
type
	Player = (White, Black);
	MoveType = (Move, Capture, Castle, Nothing);

	TPiece = class;
	TSquare = class;

	// * A square on the board
	TSquare = class(TShape)
	public
		Position: integer;
		HeldPiece: TPiece;
	end;

	// * An abstract piece on the board
	TPiece = class(TImage)
	public
		Position: TSquare;
		Color: Player;
		HasMoved: integer;

		constructor Create(square: TSquare; color: Player); reintroduce; virtual;

		function CanMoveTo(square: TSquare): MoveType; virtual;
		function CanMoveToNoCheck(square: TSquare): MoveType; virtual;
		procedure Move(square: TSquare);

		procedure ImageDblClick(sender: TObject);
		procedure ImageClick(sender: TObject);
	end;

	TPieceKing = class(TPiece)
	public
		Checked: boolean;

		constructor Create(square: TSquare; color: Player); override;

		function CanMoveTo(square: TSquare): MoveType; override;
		function CanMoveToNoCheck(square: TSquare): MoveType; override;
	end;

	TPieceQueen = class(TPiece)
	public
		constructor Create(square: TSquare; color: Player); override;

		function CanMoveTo(square: TSquare): MoveType; override;
		function CanMoveToNoCheck(square: TSquare): MoveType; override;
	end;

	TPieceRook = class(TPiece)
	public
		constructor Create(square: TSquare; color: Player); override;

		function CanMoveTo(square: TSquare): MoveType; override;
		function CanMoveToNoCheck(square: TSquare): MoveType; override;
	end;

	TPieceKnight = class(TPiece)
	public
		constructor Create(square: TSquare; color: Player); override;

		function CanMoveTo(square: TSquare): MoveType; override;
		function CanMoveToNoCheck(square: TSquare): MoveType; override;
	end;

	TPieceBishop = class(TPiece)
	public
		constructor Create(square: TSquare; color: Player); override;

		function CanMoveTo(square: TSquare): MoveType; override;
		function CanMoveToNoCheck(square: TSquare): MoveType; override;
	end;

	TPiecePawn = class(TPiece)
	public
		constructor Create(square: TSquare; color: Player); override;

		function CanMoveTo(square: TSquare): MoveType; override;
		function CanMoveToNoCheck(square: TSquare): MoveType; override;
	end;

	TMainForm = class(TForm)
	public
		Grid: array [0..63] of TSquare;
		CurrCase: TSquare;
		Turn: Player;

		Pieces: array [Player.White..Player.Black] of TObjectList<TPiece>;
		Kings: array [Player.White..Player.Black] of TPieceKing;

		procedure InitStdGameBoard;
		procedure ColorCheck;
	published
		procedure FormCreate(sender: TObject);
		procedure ShapeDblClick(sender: TObject);
		procedure ShapeClick(sender: TObject);
	end;

	TSetClick = class helper for TControl
		procedure SetOnClick(clickEvent: TNotifyEvent); inline;
		procedure SetOnDblClick(clickEvent: TNotifyEvent); inline;
	end;

var
	MainForm: TMainForm;

implementation

{$R *.dfm}

// ? Helper Functions
procedure IndexToPos(index_: integer; var x, y: integer); inline;
begin
	x := index_ mod 8;
	y := index_ div 8;
end;

function PosToIndex(x, y: integer): integer; inline;
begin
	PosToIndex := x + 8 * y;
end;

function GetOpponent(player_: Player): Player; inline;
begin
	if player_ = Player.White then
		GetOpponent := Player.Black
	else
		GetOpponent := Player.White;
end;


// ? Class Helpers
procedure TSetClick.SetOnClick(clickEvent: TNotifyEvent);
begin
	self.OnClick := clickEvent;
end;
procedure TSetClick.SetOnDblClick(clickEvent: TNotifyEvent);
begin
	self.OnDblClick := clickEvent;
end;


// ? Constructors
constructor TPiece.Create(square: TSquare; color: Player);
begin
	inherited Create(MainForm);
	
	self.Position := square;
	self.Color := color;
	self.HasMoved := 0;

	self.Height := 96;
	self.Width := 96;
	self.Top := square.Top;
	self.Left := square.Left;
	self.Stretch := true;

	self.Parent := square.Parent;
	self.Visible := true;
	self.Show;

	self.OnDblClick := ImageDblClick;
	self.OnClick := ImageClick;

	MainForm.Pieces[color].Add(self);
end;

constructor TPieceKing.Create(square: TSquare; color: Player);
begin
	inherited Create(square, color);

	self.Checked := false;

	if color = Player.White then
		self.Picture.LoadFromFile('../../Images/kingW.png')
	else
		self.Picture.LoadFromFile('../../Images/kingB.png');
end;

constructor TPieceQueen.Create(square: TSquare; color: Player);
begin
	inherited Create(square, color);

	if color = Player.White then
		self.Picture.LoadFromFile('../../Images/queenW.png')
	else
		self.Picture.LoadFromFile('../../Images/queenB.png');
end;

constructor TPieceRook.Create(square: TSquare; color: Player);
begin
	inherited Create(square, color);

	if color = Player.White then
		self.Picture.LoadFromFile('../../Images/rookW.png')
	else
		self.Picture.LoadFromFile('../../Images/rookB.png');
end;

constructor TPieceKnight.Create(square: TSquare; color: Player);
begin
	inherited Create(square, color);

	if color = Player.White then
		self.Picture.LoadFromFile('../../Images/knightW.png')
	else
		self.Picture.LoadFromFile('../../Images/knightB.png');
end;

constructor TPieceBishop.Create(square: TSquare; color: Player);
begin
	inherited Create(square, color);

	if color = Player.White then
		self.Picture.LoadFromFile('../../Images/bishopW.png')
	else
		self.Picture.LoadFromFile('../../Images/bishopB.png');
end;

constructor TPiecePawn.Create(square: TSquare; color: Player);
begin
	inherited Create(square, color);

	if color = Player.White then
		self.Picture.LoadFromFile('../../Images/pawnW.png')
	else
		self.Picture.LoadFromFile('../../Images/pawnB.png');
end;


// ? Main
procedure TMainForm.FormCreate(sender: TObject);
var
	i, x, y: integer;
	square: TSquare;
begin
	self.Color := RGB(22, 21, 18);
	self.Turn := Player.White;

	self.Pieces[Player.White] := TObjectList<TPiece>.Create;
	self.Pieces[Player.Black] := TObjectList<TPiece>.Create;

	for i := 0 to 63 do
	begin
		square := TSquare.Create(self);
		square.Parent := self;
		
		square.Height := 96;
		square.Width := 96;

		square.Position := i;
		IndexToPos(i, x, y);

		square.Left := 48 + x * 96;
		square.Top := 48 + (7-y) * 96;

		square.SetOnDblClick(ShapeDblClick);
		square.SetOnClick(ShapeClick);

		square.Visible := true;
		square.Show;

		square.Pen.Width := 48;
		if (i + i div 8) mod 2 = 0 then
		begin
			square.Pen.Color := RGB(181, 136, 99);
			square.Brush.Color := RGB(100, 110, 64);
		end
		else
		begin
			square.Pen.Color := RGB(240, 217, 181);
			square.Brush.Color := RGB(130, 151, 105);
		end;

		self.Grid[i] := square;
	end;

	self.InitStdGameBoard;
end;

procedure TMainForm.InitStdGameBoard;
begin
	self.Grid[0].HeldPiece := TPieceRook.Create(self.Grid[0], Player.White);
	self.Grid[1].HeldPiece := TPieceKnight.Create(self.Grid[1], Player.White);
	self.Grid[2].HeldPiece := TPieceBishop.Create(self.Grid[2], Player.White);
	self.Grid[3].HeldPiece := TPieceQueen.Create(self.Grid[3], Player.White);
	self.Grid[4].HeldPiece := TPieceKing.Create(self.Grid[4], Player.White);
	self.Grid[5].HeldPiece := TPieceBishop.Create(self.Grid[5], Player.White);
	self.Grid[6].HeldPiece := TPieceKnight.Create(self.Grid[6], Player.White);
	self.Grid[7].HeldPiece := TPieceRook.Create(self.Grid[7], Player.White);

	self.Grid[0 + 8].HeldPiece := TPiecePawn.Create(self.Grid[0 + 8], Player.White);
	self.Grid[1 + 8].HeldPiece := TPiecePawn.Create(self.Grid[1 + 8], Player.White);
	self.Grid[2 + 8].HeldPiece := TPiecePawn.Create(self.Grid[2 + 8], Player.White);
	self.Grid[3 + 8].HeldPiece := TPiecePawn.Create(self.Grid[3 + 8], Player.White);
	self.Grid[4 + 8].HeldPiece := TPiecePawn.Create(self.Grid[4 + 8], Player.White);
	self.Grid[5 + 8].HeldPiece := TPiecePawn.Create(self.Grid[5 + 8], Player.White);
	self.Grid[6 + 8].HeldPiece := TPiecePawn.Create(self.Grid[6 + 8], Player.White);
	self.Grid[7 + 8].HeldPiece := TPiecePawn.Create(self.Grid[7 + 8], Player.White);


	self.Grid[0 + 48].HeldPiece := TPiecePawn.Create(self.Grid[0 + 48], Player.Black);
	self.Grid[1 + 48].HeldPiece := TPiecePawn.Create(self.Grid[1 + 48], Player.Black);
	self.Grid[2 + 48].HeldPiece := TPiecePawn.Create(self.Grid[2 + 48], Player.Black);
	self.Grid[3 + 48].HeldPiece := TPiecePawn.Create(self.Grid[3 + 48], Player.Black);
	self.Grid[4 + 48].HeldPiece := TPiecePawn.Create(self.Grid[4 + 48], Player.Black);
	self.Grid[5 + 48].HeldPiece := TPiecePawn.Create(self.Grid[5 + 48], Player.Black);
	self.Grid[6 + 48].HeldPiece := TPiecePawn.Create(self.Grid[6 + 48], Player.Black);
	self.Grid[7 + 48].HeldPiece := TPiecePawn.Create(self.Grid[7 + 48], Player.Black);

	self.Grid[0 + 56].HeldPiece := TPieceRook.Create(self.Grid[0 + 56], Player.Black);
	self.Grid[1 + 56].HeldPiece := TPieceKnight.Create(self.Grid[1 + 56], Player.Black);
	self.Grid[2 + 56].HeldPiece := TPieceBishop.Create(self.Grid[2 + 56], Player.Black);
	self.Grid[3 + 56].HeldPiece := TPieceQueen.Create(self.Grid[3 + 56], Player.Black);
	self.Grid[4 + 56].HeldPiece := TPieceKing.Create(self.Grid[4 + 56], Player.Black);
	self.Grid[5 + 56].HeldPiece := TPieceBishop.Create(self.Grid[5 + 56], Player.Black);
	self.Grid[6 + 56].HeldPiece := TPieceKnight.Create(self.Grid[6 + 56], Player.Black);
	self.Grid[7 + 56].HeldPiece := TPieceRook.Create(self.Grid[7 + 56], Player.Black);

	self.Kings[Player.White] := self.Grid[4].HeldPiece as TPieceKing;
	self.Kings[Player.Black] := self.Grid[4 + 56].HeldPiece as TPieceKing;
end;

procedure TMainForm.ColorCheck;
var
	king: TPieceKing;
begin
	king := self.Kings[Player.White];
	if king.Checked then
		if (king.Position.Position + king.Position.Position div 8) mod 2 = 0 then
			king.Position.Pen.Color := RGB(208, 108, 218)
		else
			king.Position.Pen.Color := RGB(179, 67, 177)
	else
		if (king.Position.Position + king.Position.Position div 8) mod 2 = 0 then
			king.Position.Pen.Color := RGB(181, 136, 99)
		else
			king.Position.Pen.Color := RGB(240, 217, 181);

	king := self.Kings[Player.Black];
	if king.Checked then
		if (king.Position.Position + king.Position.Position div 8) mod 2 = 0 then
			king.Position.Pen.Color := RGB(208, 108, 218)
		else
			king.Position.Pen.Color := RGB(179, 67, 177)
	else
		if (king.Position.Position + king.Position.Position div 8) mod 2 = 0 then
			king.Position.Pen.Color := RGB(181, 136, 99)
		else
			king.Position.Pen.Color := RGB(240, 217, 181);
end;

procedure TPiece.Move(square: TSquare);
begin
	if square.HeldPiece <> nil then
		MainForm.Pieces[GetOpponent(MainForm.Turn)].Remove(square.HeldPiece);

	square.HeldPiece := self;

	self.Position.HeldPiece := nil;
	self.Position := square;

	self.Top := square.Top;
	self.Left := square.Left;

	self.HasMoved := self.HasMoved + 1;
	MainForm.Turn := GetOpponent(MainForm.Turn);
end;

// * Move Function
function TPiece.CanMoveTo(square: TSquare): MoveType;
var
	tempPiece: TPiece;
	tempSquare: TSquare;

	king: TPieceKing;
	i: integer;
	piece: TPiece;
begin
	CanMoveTo := MoveType.Move;

	tempPiece := square.HeldPiece;
	tempSquare := self.Position;

	square.HeldPiece := self;
	tempSquare.HeldPiece := nil;
	self.Position := square;

	king := MainForm.Kings[self.Color];
	for i := 0 to MainForm.Pieces[GetOpponent(self.Color)].Count - 1 do
	begin
		piece := MainForm.Pieces[GetOpponent(self.Color)][i];
		if piece.CanMoveToNoCheck(king.Position) = MoveType.Capture then
		begin
			CanMoveTo := MoveType.Nothing;
			break;
		end;
	end;

	square.HeldPiece := tempPiece;
	tempSquare.HeldPiece := self;
	self.Position := tempSquare;
end;

function TPiece.CanMoveToNoCheck(square: TSquare): MoveType;
begin
	CanMoveToNoCheck := MoveType.Nothing;
end;

function TPieceKing.CanMoveTo(square: TSquare): MoveType;
var
	selfX, selfY: integer;
	otherX, otherY: integer;
	moveX, moveY: integer;

	temp: MoveType;
begin
	CanMoveTo := MoveType.Nothing;

	IndexToPos(self.Position.Position, selfX, selfY);
	IndexToPos(square.Position, otherX, otherY);
	moveX := otherX - selfX;
	moveY := otherY - selfY;

	if (abs(moveX) <= 1) and (abs(moveY) <= 1) then
	begin
		if square.HeldPiece = nil then
			CanMoveTo := MoveType.Move
		else if square.HeldPiece.Color <> self.Color then
			CanMoveTo := MoveType.Capture;

		temp := inherited CanMoveTo(square);
		if temp = MoveType.Nothing then
			CanMoveTo := MoveType.Nothing;
	end
	else if (self.HasMoved = 0) and ((self.Position.Position = 4) or ((self.Position.Position = 60)))
	and (moveX = -2) and (moveY = 0) and (not self.Checked)
	and (MainForm.Grid[self.Position.Position - 3].HeldPiece = nil)
	and (MainForm.Grid[self.Position.Position - 2].HeldPiece = nil)
	and (MainForm.Grid[self.Position.Position - 1].HeldPiece = nil)
	and (inherited CanMoveTo(MainForm.Grid[self.Position.Position - 2]) = MoveType.Move)
	and (inherited CanMoveTo(MainForm.Grid[self.Position.Position - 1]) = MoveType.Move)
	and (MainForm.Grid[0].HeldPiece.HasMoved = 0) then
		CanMoveTo := MoveType.Castle
	else if (self.HasMoved = 0) and ((self.Position.Position = 4) or ((self.Position.Position = 60)))
	and (moveX = 2) and (moveY = 0) and (not self.Checked)
	and (MainForm.Grid[self.Position.Position + 1].HeldPiece = nil)
	and (MainForm.Grid[self.Position.Position + 2].HeldPiece = nil)
	and (inherited CanMoveTo(MainForm.Grid[self.Position.Position + 1]) = MoveType.Move)
	and (inherited CanMoveTo(MainForm.Grid[self.Position.Position + 2]) = MoveType.Move)
	and (MainForm.Grid[7].HeldPiece.HasMoved = 0) then
		CanMoveTo := MoveType.Castle;
end;

function TPieceKing.CanMoveToNoCheck(square: TSquare): MoveType;
var
	selfX, selfY: integer;
	otherX, otherY: integer;
	moveX, moveY: integer;
begin
	CanMoveToNoCheck := MoveType.Nothing;

	IndexToPos(self.Position.Position, selfX, selfY);
	IndexToPos(square.Position, otherX, otherY);
	moveX := otherX - selfX;
	moveY := otherY - selfY;

	if (abs(moveX) <= 1) and (abs(moveY) <= 1) then
	begin
		if square.HeldPiece = nil then
			CanMoveToNoCheck := MoveType.Move
		else if square.HeldPiece.Color <> self.Color then
			CanMoveToNoCheck := MoveType.Capture;
	end
	else if (self.HasMoved = 0) and (self.Position.Position = 4) and (moveX = -2) and (moveY = 0) and (not self.Checked)
	and (MainForm.Grid[self.Position.Position - 3].HeldPiece = nil)
	and (MainForm.Grid[self.Position.Position - 2].HeldPiece = nil)
	and (MainForm.Grid[self.Position.Position - 1].HeldPiece = nil)
	and (inherited CanMoveToNoCheck(MainForm.Grid[self.Position.Position - 2]) = MoveType.Move)
	and (inherited CanMoveToNoCheck(MainForm.Grid[self.Position.Position - 1]) = MoveType.Move)
	and (MainForm.Grid[0].HeldPiece.HasMoved = 0) then
		CanMoveToNoCheck := MoveType.Castle
	else if (self.HasMoved = 0) and (self.Position.Position = 4) and (moveX = 2) and (moveY = 0) and (not self.Checked)
	and (MainForm.Grid[self.Position.Position + 1].HeldPiece = nil)
	and (MainForm.Grid[self.Position.Position + 2].HeldPiece = nil)
	and (inherited CanMoveToNoCheck(MainForm.Grid[self.Position.Position + 1]) = MoveType.Move)
	and (inherited CanMoveToNoCheck(MainForm.Grid[self.Position.Position + 2]) = MoveType.Move)
	and (MainForm.Grid[7].HeldPiece.HasMoved = 0) then
		CanMoveToNoCheck := MoveType.Castle;
end;

function TPieceQueen.CanMoveTo(square: TSquare): MoveType;
var
	selfX, selfY: integer;
	otherX, otherY: integer;
	moveX, moveY: integer;

	temp: MoveType;
begin
	CanMoveTo := MoveType.Nothing;

	IndexToPos(self.Position.Position, selfX, selfY);
	IndexToPos(square.Position, otherX, otherY);
	moveX := otherX - selfX;
	moveY := otherY - selfY;

	if (abs(moveX) + abs(moveY) = 1) or ((abs(moveX) = 1) and (abs(moveY) = 1))
	or ((moveX = 0) and (abs(moveY) > 1) and (self.CanMoveTo(MainForm.Grid[PosToIndex(otherX, otherY - (moveY div abs(moveY)))]) = MoveType.Move))
	or ((moveY = 0) and (abs(moveX) > 1) and (self.CanMoveTo(MainForm.Grid[PosToIndex(otherX - (moveX div abs(moveX)), otherY)]) = MoveType.Move))
	or ((abs(moveX) = abs(moveY)) and (moveX <> 0)
		and (self.CanMoveTo(MainForm.Grid[PosToIndex(otherX - (moveX div abs(moveX)), otherY - (moveY div abs(moveY)))]) = MoveType.Move)) then
	begin
		if square.HeldPiece = nil then
			CanMoveTo := MoveType.Move
		else if square.HeldPiece.Color <> self.Color then
			CanMoveTo := MoveType.Capture;
		
		temp := inherited CanMoveTo(square);
		if temp = MoveType.Nothing then
			CanMoveTo := MoveType.Nothing;
	end;
end;

function TPieceQueen.CanMoveToNoCheck(square: TSquare): MoveType;
var
	selfX, selfY: integer;
	otherX, otherY: integer;
	moveX, moveY: integer;
begin
	CanMoveToNoCheck := MoveType.Nothing;

	IndexToPos(self.Position.Position, selfX, selfY);
	IndexToPos(square.Position, otherX, otherY);
	moveX := otherX - selfX;
	moveY := otherY - selfY;

	if (abs(moveX) + abs(moveY) = 1) or ((abs(moveX) = 1) and (abs(moveY) = 1))
	or ((moveX = 0) and (abs(moveY) > 1) and (self.CanMoveToNoCheck(MainForm.Grid[PosToIndex(otherX, otherY - (moveY div abs(moveY)))]) = MoveType.Move))
	or ((moveY = 0) and (abs(moveX) > 1) and (self.CanMoveToNoCheck(MainForm.Grid[PosToIndex(otherX - (moveX div abs(moveX)), otherY)]) = MoveType.Move))
	or ((abs(moveX) = abs(moveY)) and (moveX <> 0)
		and (self.CanMoveToNoCheck(MainForm.Grid[PosToIndex(otherX - (moveX div abs(moveX)), otherY - (moveY div abs(moveY)))]) = MoveType.Move)) then
		if square.HeldPiece = nil then
			CanMoveToNoCheck := MoveType.Move
		else if square.HeldPiece.Color <> self.Color then
			CanMoveToNoCheck := MoveType.Capture;
		
end;

function TPieceRook.CanMoveTo(square: TSquare): MoveType;
var
	selfX, selfY: integer;
	otherX, otherY: integer;
	moveX, moveY: integer;

	temp: MoveType;
begin
	CanMoveTo := MoveType.Nothing;

	IndexToPos(self.Position.Position, selfX, selfY);
	IndexToPos(square.Position, otherX, otherY);
	moveX := otherX - selfX;
	moveY := otherY - selfY;

	if (abs(moveX) + abs(moveY) = 1)
	or ((moveX = 0) and (abs(moveY) > 1) and (self.CanMoveTo(MainForm.Grid[PosToIndex(otherX, otherY - (moveY div abs(moveY)))]) = MoveType.Move))
	or ((moveY = 0) and (abs(moveX) > 1) and (self.CanMoveTo(MainForm.Grid[PosToIndex(otherX - (moveX div abs(moveX)), otherY)]) = MoveType.Move)) then
	begin
		if square.HeldPiece = nil then
			CanMoveTo := MoveType.Move
		else if square.HeldPiece.Color <> self.Color then
			CanMoveTo := MoveType.Capture;
		
		temp := inherited CanMoveTo(square);
		if temp = MoveType.Nothing then
			CanMoveTo := MoveType.Nothing;
	end;
end;

function TPieceRook.CanMoveToNoCheck(square: TSquare): MoveType;
var
	selfX, selfY: integer;
	otherX, otherY: integer;
	moveX, moveY: integer;
begin
	CanMoveToNoCheck := MoveType.Nothing;

	IndexToPos(self.Position.Position, selfX, selfY);
	IndexToPos(square.Position, otherX, otherY);
	moveX := otherX - selfX;
	moveY := otherY - selfY;

	if (abs(moveX) + abs(moveY) = 1)
	or ((moveX = 0) and (abs(moveY) > 1) and (self.CanMoveToNoCheck(MainForm.Grid[PosToIndex(otherX, otherY - (moveY div abs(moveY)))]) = MoveType.Move))
	or ((moveY = 0) and (abs(moveX) > 1) and (self.CanMoveToNoCheck(MainForm.Grid[PosToIndex(otherX - (moveX div abs(moveX)), otherY)]) = MoveType.Move)) then
		if square.HeldPiece = nil then
			CanMoveToNoCheck := MoveType.Move
		else if square.HeldPiece.Color <> self.Color then
			CanMoveToNoCheck := MoveType.Capture;
		
end;

function TPieceKnight.CanMoveTo(square: TSquare): MoveType;
var
	selfX, selfY: integer;
	otherX, otherY: integer;
	moveX, moveY: integer;

	temp: MoveType;
begin
	CanMoveTo := MoveType.Nothing;

	IndexToPos(self.Position.Position, selfX, selfY);
	IndexToPos(square.Position, otherX, otherY);
	moveX := otherX - selfX;
	moveY := otherY - selfY;

	if (power(moveX, 2) + power(moveY, 2)) = 5 then
	begin
		if square.HeldPiece = nil then
			CanMoveTo := MoveType.Move
		else if square.HeldPiece.Color <> self.Color then
			CanMoveTo := MoveType.Capture;
		
		temp := inherited CanMoveTo(square);
		if temp = MoveType.Nothing then
			CanMoveTo := MoveType.Nothing;
	end;
end;

function TPieceKnight.CanMoveToNoCheck(square: TSquare): MoveType;
var
	selfX, selfY: integer;
	otherX, otherY: integer;
	moveX, moveY: integer;
begin
	CanMoveToNoCheck := MoveType.Nothing;

	IndexToPos(self.Position.Position, selfX, selfY);
	IndexToPos(square.Position, otherX, otherY);
	moveX := otherX - selfX;
	moveY := otherY - selfY;

	if (power(moveX, 2) + power(moveY, 2)) = 5 then
		if square.HeldPiece = nil then
			CanMoveToNoCheck := MoveType.Move
		else if square.HeldPiece.Color <> self.Color then
			CanMoveToNoCheck := MoveType.Capture;
		
end;

function TPieceBishop.CanMoveTo(square: TSquare): MoveType;
var
	selfX, selfY: integer;
	otherX, otherY: integer;
	moveX, moveY: integer;

	temp: MoveType;
begin
	CanMoveTo := MoveType.Nothing;

	IndexToPos(self.Position.Position, selfX, selfY);
	IndexToPos(square.Position, otherX, otherY);
	moveX := otherX - selfX;
	moveY := otherY - selfY;

	if ((abs(moveX) = 1) and (abs(moveY) = 1))
	or ((abs(moveX) = abs(moveY)) and (moveX <> 0)
		and (self.CanMoveTo(MainForm.Grid[PosToIndex(otherX - (moveX div abs(moveX)), otherY - (moveY div abs(moveY)))]) = MoveType.Move)) then
	begin
		if square.HeldPiece = nil then
			CanMoveTo := MoveType.Move
		else if square.HeldPiece.Color <> self.Color then
			CanMoveTo := MoveType.Capture;
		
		temp := inherited CanMoveTo(square);
		if temp = MoveType.Nothing then
			CanMoveTo := MoveType.Nothing;
	end;
end;

function TPieceBishop.CanMoveToNoCheck(square: TSquare): MoveType;
var
	selfX, selfY: integer;
	otherX, otherY: integer;
	moveX, moveY: integer;
begin
	CanMoveToNoCheck := MoveType.Nothing;

	IndexToPos(self.Position.Position, selfX, selfY);
	IndexToPos(square.Position, otherX, otherY);
	moveX := otherX - selfX;
	moveY := otherY - selfY;

	if ((abs(moveX) = 1) and (abs(moveY) = 1))
	or ((abs(moveX) = abs(moveY)) and (moveX <> 0)
		and (self.CanMoveToNoCheck(MainForm.Grid[PosToIndex(otherX - (moveX div abs(moveX)), otherY - (moveY div abs(moveY)))]) = MoveType.Move)) then
		if square.HeldPiece = nil then
			CanMoveToNoCheck := MoveType.Move
		else if square.HeldPiece.Color <> self.Color then
			CanMoveToNoCheck := MoveType.Capture;
		
end;

function TPiecePawn.CanMoveTo(square: TSquare): MoveType;
var
	selfX, selfY: integer;
	otherX, otherY: integer;
	moveX, moveY: integer;

	direction: integer;
	doubleMove: boolean;

	temp: MoveType;
begin
	CanMoveTo := MoveType.Nothing;

	IndexToPos(self.Position.Position, selfX, selfY);
	IndexToPos(square.Position, otherX, otherY);
	moveX := otherX - selfX;
	moveY := otherY - selfY;

	doubleMove := false;
	if ((selfY = 1) and (self.Color = Player.White))
	or ((selfY = 6) and (self.Color = Player.Black)) then
		doubleMove := true;

	if self.Color = Player.White then
		direction := moveY
	else
		direction := -moveY;
	
	if square.HeldPiece = nil then
	begin
		if (abs(moveY) = 1) and (moveX = 0) and (direction > 0) then
			CanMoveTo := MoveType.Move
		else if doubleMove and (abs(moveY) = 2) and (moveX = 0) and (direction > 0)
		and (MainForm.Grid[PosToIndex(otherX, otherY - (moveY div abs(moveY)))].HeldPiece = nil) then
			CanMoveTo := MoveType.Move
		else if (abs(moveX) = 1) and (direction = 1)
		and (MainForm.Grid[PosToIndex(otherX, otherY - (moveY div abs(moveY)))].HeldPiece <> nil) then
			if (MainForm.Grid[PosToIndex(otherX, otherY - (moveY div abs(moveY)))].HeldPiece.ClassType = TPiecePawn)
			and (MainForm.Grid[PosToIndex(otherX, otherY - (moveY div abs(moveY)))].HeldPiece.HasMoved = 1) then
				CanMoveTo := MoveType.Capture;
		
		temp := inherited CanMoveTo(square);
		if temp = MoveType.Nothing then
			CanMoveTo := MoveType.Nothing;
	end
	else if (square.HeldPiece.Color <> self.Color) and (abs(moveX) = 1) and (direction = 1) then
	begin
		CanMoveTo := MoveType.Capture;
		
		temp := inherited CanMoveTo(square);
		if temp = MoveType.Nothing then
			CanMoveTo := MoveType.Nothing;
	end;
end;

function TPiecePawn.CanMoveToNoCheck(square: TSquare): MoveType;
var
	selfX, selfY: integer;
	otherX, otherY: integer;
	moveX, moveY: integer;

	direction: integer;
	doubleMove: boolean;
begin
	CanMoveToNoCheck := MoveType.Nothing;

	IndexToPos(self.Position.Position, selfX, selfY);
	IndexToPos(square.Position, otherX, otherY);
	moveX := otherX - selfX;
	moveY := otherY - selfY;

	doubleMove := false;
	if ((selfY = 1) and (self.Color = Player.White))
	or ((selfY = 6) and (self.Color = Player.Black)) then
		doubleMove := true;

	if self.Color = Player.White then
		direction := moveY
	else
		direction := -moveY;
	
	if square.HeldPiece = nil then
	begin
		if (abs(moveY) = 1) and (moveX = 0) and (direction > 0) then
			CanMoveToNoCheck := MoveType.Move
		else if doubleMove and (abs(moveY) = 2) and (moveX = 0) and (direction > 0)
		and (MainForm.Grid[PosToIndex(otherX, otherY - (moveY div abs(moveY)))].HeldPiece = nil) then
			CanMoveToNoCheck := MoveType.Move
		else if (abs(moveX) = 1) and (direction = 1)
		and (MainForm.Grid[PosToIndex(otherX, otherY - (moveY div abs(moveY)))].HeldPiece <> nil) then
			if (MainForm.Grid[PosToIndex(otherX, otherY - (moveY div abs(moveY)))].HeldPiece.ClassType = TPiecePawn)
			and (MainForm.Grid[PosToIndex(otherX, otherY - (moveY div abs(moveY)))].HeldPiece.HasMoved = 1) then
				CanMoveToNoCheck := MoveType.Capture;
	end
	else if (square.HeldPiece.Color <> self.Color) and (abs(moveX) = 1) and (direction = 1) then
		CanMoveToNoCheck := MoveType.Capture;
end;


// ? Events
procedure TMainForm.ShapeDblClick(sender: TObject);
var
	square: TSquare;
	i: integer;

	temp: MoveType;
begin
	square := sender as TSquare;

	// Reset colors
	for i := 0 to 63 do
		if (i + i div 8) mod 2 = 0 then
			self.Grid[i].Pen.Color := RGB(181, 136, 99)
		else
			self.Grid[i].Pen.Color := RGB(240, 217, 181);

	if square = self.CurrCase then
	begin
		self.CurrCase := nil;
		exit;
	end;

	self.CurrCase := nil;

	if square.HeldPiece = nil then
		exit;
	
	self.ColorCheck;

	if square.HeldPiece.Color <> self.Turn then
		exit;

	// Color the possible move cells
	for i := 0 to 63 do
	begin
		temp := square.HeldPiece.CanMoveTo(self.Grid[i]);
		if temp = MoveType.Capture then
			if (i + i div 8) mod 2 = 0 then
				self.Grid[i].Pen.Color := RGB(216, 69, 50)
			else
				self.Grid[i].Pen.Color := RGB(247, 111, 92)
		else if temp = MoveType.Move then
			if (i + i div 8) mod 2 = 0 then
				self.Grid[i].Pen.Color := RGB(90, 87, 176)
			else
				self.Grid[i].Pen.Color := RGB(120, 127, 217)
		else if temp = MoveType.Castle then
			if (i + i div 8) mod 2 = 0 then
				self.Grid[i].Pen.Color := RGB(90, 195, 65)
			else
				self.Grid[i].Pen.Color := RGB(119, 236, 106);
	end;

	self.ColorCheck;

	// Color the current cell
	if (square.Position + square.Position div 8) mod 2 = 0 then
		square.Pen.Color := RGB(100, 110, 64)
	else
		square.Pen.Color := RGB(130, 151, 105);

	self.CurrCase := square;
end;

procedure TMainForm.ShapeClick(sender: TObject);
var
	square: TSquare;

	i, j: integer;
	piece: TPiece;
	king: TPieceKing;

	temp: boolean;
	direction: integer;
begin
	square := sender as TSquare;

	if self.CurrCase = nil then
		exit;

	for i := 0 to 63 do
		if self.Grid[i].HeldPiece <> nil then
			if self.Grid[i].HeldPiece.HasMoved > 0 then
				self.Grid[i].HeldPiece.HasMoved := self.Grid[i].HeldPiece.HasMoved + 1;

	// Handles move & capture
	if (square.Pen.Color = integer(RGB(90, 87, 176))) or (square.Pen.Color = integer(RGB(120, 127, 217)))
	or (square.Pen.Color = integer(RGB(216, 69, 50))) or (square.Pen.Color = integer(RGB(247, 111, 92))) then
	begin
		if self.CurrCase.HeldPiece.ClassType = TPiecePawn then
		begin
			if ((self.CurrCase.HeldPiece.Color = Player.White) and ((square.Position div 8) = 7))
			or ((self.CurrCase.HeldPiece.Color = Player.Black) and ((square.Position div 8) = 0)) then
			begin
				self.Pieces[self.Turn].Remove(self.CurrCase.HeldPiece);
				self.CurrCase.HeldPiece := TPieceQueen.Create(self.CurrCase, self.Turn);
			end;
			if (square.HeldPiece = nil)
			and ((square.Pen.Color = integer(RGB(216, 69, 50))) or (square.Pen.Color = integer(RGB(247, 111, 92)))) then
			begin
				direction := (square.Position div 8) - (self.CurrCase.Position div 8);
				self.Pieces[GetOpponent(self.Turn)].Remove(self.Grid[square.Position - 8 * direction].HeldPiece);
			end;
		end;
		self.CurrCase.HeldPiece.Move(square);
	end
	else if (square.Pen.Color = integer(RGB(90, 195, 65))) or (square.Pen.Color = integer(RGB(119, 236, 106))) then
	begin
		if (square.Position = 2) or (square.Position = 58) then
		begin
			self.CurrCase.HeldPiece.Move(square);
			self.Grid[square.Position - 2].HeldPiece.Move(self.Grid[square.Position + 1])
		end
		else
		begin
			self.CurrCase.HeldPiece.Move(square);
			self.Grid[square.Position + 1].HeldPiece.Move(self.Grid[square.Position - 1])
		end;

		self.Turn := GetOpponent(self.Turn);
	end;

	// Reset colors
	for i := 0 to 63 do
		if (i + i div 8) mod 2 = 0 then
			self.Grid[i].Pen.Color := RGB(181, 136, 99)
		else
			self.Grid[i].Pen.Color := RGB(240, 217, 181);

	// Handles check
	king := self.Kings[self.Turn];
	king.Checked := false;
	for i := 0 to self.Pieces[GetOpponent(self.Turn)].Count - 1 do
	begin
		piece := self.Pieces[GetOpponent(self.Turn)][i];
		if piece.CanMoveTo(king.Position) = MoveType.Capture then
		begin
			king.Checked := true;
			break;
		end;
	end;

	king := self.Kings[GetOpponent(self.Turn)];
	king.Checked := false;
	for i := 0 to self.Pieces[GetOpponent(self.Turn)].Count - 1 do
	begin
		piece := self.Pieces[GetOpponent(self.Turn)][i];
		if piece.CanMoveTo(king.Position) = MoveType.Capture then
		begin
			king.Checked := true;
			break;
		end;
	end;
	
	self.ColorCheck;

	self.CurrCase := nil;

	// Check for checkmate/draw
	temp := true;
	for i := 0 to self.Pieces[self.Turn].Count - 1 do
	begin
		piece := self.Pieces[self.Turn][i];
		for j := 0 to 63 do
			if piece.CanMoveTo(self.Grid[j]) <> MoveType.Nothing then
				temp := false;
	end;
	
	if temp then
		if self.Kings[Player.White].Checked then
			ShowMessage('Checkmate.' + sLineBreak + 'Black is victorious!')
		else if self.Kings[Player.Black].Checked then
			ShowMessage('Checkmate.' + sLineBreak + 'White is victorious!')
		else
			ShowMessage('Draw');
end;

procedure TPiece.ImageDblClick(sender: TObject);
var
	piece: TPiece;
begin
	piece := sender as TPiece;

	piece.Position.DblClick;
end;

procedure TPiece.ImageClick(sender: TObject);
var
	piece: TPiece;
begin
	piece := sender as TPiece;

	piece.Position.Click;
end;

end.