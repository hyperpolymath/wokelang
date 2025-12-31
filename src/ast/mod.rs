use std::ops::Range;

/// Source span for error reporting
pub type Span = Range<usize>;

/// A spanned AST node
#[derive(Debug, Clone)]
pub struct Spanned<T> {
    pub node: T,
    pub span: Span,
}

impl<T> Spanned<T> {
    pub fn new(node: T, span: Span) -> Self {
        Self { node, span }
    }
}

/// The root of a WokeLang program
#[derive(Debug, Clone)]
pub struct Program {
    pub items: Vec<TopLevelItem>,
}

/// Top-level items in a program
#[derive(Debug, Clone)]
pub enum TopLevelItem {
    Function(FunctionDef),
    ConsentBlock(ConsentBlock),
    GratitudeDecl(GratitudeDecl),
    WorkerDef(WorkerDef),
    SideQuestDef(SideQuestDef),
    SuperpowerDecl(SuperpowerDecl),
    ModuleImport(ModuleImport),
    Pragma(Pragma),
    TypeDef(TypeDef),
    ConstDef(ConstDef),
}

/// Module import: `use foo.bar renamed baz;`
#[derive(Debug, Clone)]
pub struct ModuleImport {
    pub path: QualifiedName,
    pub rename: Option<String>,
    pub span: Span,
}

/// Qualified name: `foo.bar.baz`
#[derive(Debug, Clone)]
pub struct QualifiedName {
    pub parts: Vec<String>,
    pub span: Span,
}

/// Function definition
#[derive(Debug, Clone)]
pub struct FunctionDef {
    pub emote: Option<EmoteTag>,
    pub name: String,
    pub params: Vec<Parameter>,
    pub return_type: Option<Type>,
    pub hello: Option<String>,
    pub body: Vec<Statement>,
    pub goodbye: Option<String>,
    pub span: Span,
}

/// Function parameter
#[derive(Debug, Clone)]
pub struct Parameter {
    pub name: String,
    pub ty: Option<Type>,
    pub span: Span,
}

/// Consent block: `only if okay "permission" { ... }`
#[derive(Debug, Clone)]
pub struct ConsentBlock {
    pub permission: String,
    pub body: Vec<Statement>,
    pub span: Span,
}

/// Gratitude declaration: `thanks to { ... }`
#[derive(Debug, Clone)]
pub struct GratitudeDecl {
    pub entries: Vec<GratitudeEntry>,
    pub span: Span,
}

/// Single gratitude entry: `"name" → "reason";`
#[derive(Debug, Clone)]
pub struct GratitudeEntry {
    pub recipient: String,
    pub reason: String,
    pub span: Span,
}

/// Statement types
#[derive(Debug, Clone)]
pub enum Statement {
    /// `remember x = expr;`
    VarDecl(VarDecl),
    /// `x = expr;`
    Assignment(Assignment),
    /// `give back expr;`
    Return(ReturnStmt),
    /// `when expr { ... } otherwise { ... }`
    Conditional(Conditional),
    /// `repeat n times { ... }`
    Loop(Loop),
    /// `attempt safely { ... } or reassure "msg";`
    AttemptBlock(AttemptBlock),
    /// `only if okay "perm" { ... }`
    ConsentBlock(ConsentBlock),
    /// `expr;`
    Expression(Spanned<Expr>),
    /// `spawn worker name;`
    WorkerSpawn(WorkerSpawn),
    /// `complain "message";`
    Complain(ComplainStmt),
    /// `@emote statement`
    EmoteAnnotated(EmoteAnnotatedStmt),
    /// `decide based on expr { ... }`
    Decide(DecideStmt),
}

/// Variable declaration: `remember x = expr measured in unit;`
#[derive(Debug, Clone)]
pub struct VarDecl {
    pub name: String,
    pub value: Spanned<Expr>,
    pub unit: Option<String>,
    pub span: Span,
}

/// Assignment: `x = expr;`
#[derive(Debug, Clone)]
pub struct Assignment {
    pub target: String,
    pub value: Spanned<Expr>,
    pub span: Span,
}

/// Return statement: `give back expr;`
#[derive(Debug, Clone)]
pub struct ReturnStmt {
    pub value: Spanned<Expr>,
    pub span: Span,
}

/// Conditional: `when expr { ... } otherwise { ... }`
#[derive(Debug, Clone)]
pub struct Conditional {
    pub condition: Spanned<Expr>,
    pub then_branch: Vec<Statement>,
    pub else_branch: Option<Vec<Statement>>,
    pub span: Span,
}

/// Loop: `repeat n times { ... }`
#[derive(Debug, Clone)]
pub struct Loop {
    pub count: Spanned<Expr>,
    pub body: Vec<Statement>,
    pub span: Span,
}

/// Attempt block: `attempt safely { ... } or reassure "msg";`
#[derive(Debug, Clone)]
pub struct AttemptBlock {
    pub body: Vec<Statement>,
    pub reassurance: String,
    pub span: Span,
}

/// Worker spawn: `spawn worker name;`
#[derive(Debug, Clone)]
pub struct WorkerSpawn {
    pub worker_name: String,
    pub span: Span,
}

/// Complain statement: `complain "message";`
#[derive(Debug, Clone)]
pub struct ComplainStmt {
    pub message: String,
    pub span: Span,
}

/// Emote-annotated statement: `@emote statement`
#[derive(Debug, Clone)]
pub struct EmoteAnnotatedStmt {
    pub emote: EmoteTag,
    pub statement: Box<Statement>,
    pub span: Span,
}

/// Decide statement (pattern matching): `decide based on expr { ... }`
#[derive(Debug, Clone)]
pub struct DecideStmt {
    pub scrutinee: Spanned<Expr>,
    pub arms: Vec<MatchArm>,
    pub span: Span,
}

/// Match arm: `pattern → { ... }`
#[derive(Debug, Clone)]
pub struct MatchArm {
    pub pattern: Pattern,
    pub body: Vec<Statement>,
    pub span: Span,
}

/// Pattern for matching
#[derive(Debug, Clone)]
pub enum Pattern {
    /// Literal pattern: `42`, `"hello"`, `true`
    Literal(Literal),
    /// Identifier pattern (binds value): `x`
    Identifier(String),
    /// Wildcard pattern: `_`
    Wildcard,
    /// Constructor pattern: `Okay(x)`, `Oops(e)`
    Constructor(String, Option<Box<Pattern>>),
}

/// Expression types
#[derive(Debug, Clone)]
pub enum Expr {
    /// Literal value
    Literal(Literal),
    /// Variable reference
    Identifier(String),
    /// Binary operation
    Binary(BinaryOp, Box<Spanned<Expr>>, Box<Spanned<Expr>>),
    /// Unary operation
    Unary(UnaryOp, Box<Spanned<Expr>>),
    /// Function call by name
    Call(String, Vec<Spanned<Expr>>),
    /// Call expression: `expr(args)` - for calling closures
    CallExpr(Box<Spanned<Expr>>, Vec<Spanned<Expr>>),
    /// Unit measurement: `expr measured in unit`
    UnitMeasurement(Box<Spanned<Expr>>, String),
    /// Gratitude literal: `thanks("name")`
    GratitudeLiteral(String),
    /// Array literal
    Array(Vec<Spanned<Expr>>),
    /// Index access: `arr[i]` or `str[i]`
    Index(Box<Spanned<Expr>>, Box<Spanned<Expr>>),
    /// Result success: `Okay(expr)`
    Okay(Box<Spanned<Expr>>),
    /// Result error: `Oops(expr)`
    Oops(Box<Spanned<Expr>>),
    /// Unwrap result: `expr?` or `unwrap(expr)`
    Unwrap(Box<Spanned<Expr>>),
    /// Lambda/closure: `|x, y| -> expr` or `|x, y| { ... }`
    Lambda(LambdaExpr),
}

/// Binary operators
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum BinaryOp {
    Add,
    Sub,
    Mul,
    Div,
    Mod,
    Eq,
    NotEq,
    Lt,
    Gt,
    LtEq,
    GtEq,
    And,
    Or,
}

/// Unary operators
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum UnaryOp {
    Neg,
    Not,
}

/// Literal values
#[derive(Debug, Clone)]
pub enum Literal {
    Integer(i64),
    Float(f64),
    String(String),
    Bool(bool),
}

/// Lambda expression body
#[derive(Debug, Clone)]
pub enum LambdaBody {
    /// Expression body: `|x| -> x + 1`
    Expr(Box<Spanned<Expr>>),
    /// Block body: `|x| { give back x + 1; }`
    Block(Vec<Statement>),
}

/// Lambda/closure expression: `|x, y| -> expr` or `|x, y| { ... }`
#[derive(Debug, Clone)]
pub struct LambdaExpr {
    pub params: Vec<Parameter>,
    pub return_type: Option<Type>,
    pub body: LambdaBody,
}

/// Emote tag: `@name(params)`
#[derive(Debug, Clone)]
pub struct EmoteTag {
    pub name: String,
    pub params: Vec<EmoteParam>,
    pub span: Span,
}

/// Emote parameter: `name=value`
#[derive(Debug, Clone)]
pub struct EmoteParam {
    pub name: String,
    pub value: EmoteValue,
}

/// Emote parameter value
#[derive(Debug, Clone)]
pub enum EmoteValue {
    Number(f64),
    String(String),
    Identifier(String),
}

/// Worker definition: `worker name { ... }`
#[derive(Debug, Clone)]
pub struct WorkerDef {
    pub name: String,
    pub body: Vec<Statement>,
    pub span: Span,
}

/// Side quest definition: `side quest name { ... }`
#[derive(Debug, Clone)]
pub struct SideQuestDef {
    pub name: String,
    pub body: Vec<Statement>,
    pub span: Span,
}

/// Superpower declaration: `superpower name { ... }`
#[derive(Debug, Clone)]
pub struct SuperpowerDecl {
    pub name: String,
    pub body: Vec<Statement>,
    pub span: Span,
}

/// Pragma: `#care on;`
#[derive(Debug, Clone)]
pub struct Pragma {
    pub directive: PragmaDirective,
    pub enabled: bool,
    pub span: Span,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum PragmaDirective {
    Care,
    Strict,
    Verbose,
}

/// Type annotation
#[derive(Debug, Clone, PartialEq)]
pub enum Type {
    /// Basic types: String, Int, Float, Bool, or custom
    Basic(String),
    /// Array type: [T]
    Array(Box<Type>),
    /// Optional type: Maybe T
    Optional(Box<Type>),
    /// Reference type: &T
    Reference(Box<Type>),
    /// Function type: (T1, T2) -> R
    Function(Vec<Type>, Box<Type>),
}

/// Type definition: `type Name = ...;`
#[derive(Debug, Clone)]
pub struct TypeDef {
    pub name: String,
    pub definition: TypeVariant,
    pub span: Span,
}

/// Type variant for type definitions
#[derive(Debug, Clone)]
pub enum TypeVariant {
    /// Struct: `{ field: Type, ... }`
    Struct(Vec<Field>),
    /// Enum: `Variant1 | Variant2(Type)`
    Enum(Vec<Variant>),
    /// Alias: `= OtherType`
    Alias(Type),
}

/// Struct field
#[derive(Debug, Clone)]
pub struct Field {
    pub name: String,
    pub ty: Type,
}

/// Enum variant
#[derive(Debug, Clone)]
pub struct Variant {
    pub name: String,
    pub fields: Vec<Type>,
}

/// Constant definition: `const NAME: Type = expr;`
#[derive(Debug, Clone)]
pub struct ConstDef {
    pub name: String,
    pub ty: Type,
    pub value: Spanned<Expr>,
    pub span: Span,
}
