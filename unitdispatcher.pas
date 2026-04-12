unit unitdispatcher;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Menus, ComCtrls, Buttons, Spin, Grids, ValEdit,
  comUnit, Types;

type

  //***************************************
  //Production plan obtained by ERP and available in the DB
  // Enumerated: defines the type of the TTask
  TTask_Type  = (Type_Expedition = 1, Type_Delivery, Type_Production, Type_Trash);

  // TBC by a Query to DB
  TProduction_Order = record
    part_type           : Integer;    // Part type { 0, ... 9}
    part_numbers        : Integer;    // Number of parts to be performed
    order_type          : TTask_Type;
  end;

  TArray_Production_Order = array of TProduction_Order; // This array shall be completed by the SQL query
  //***************************************

  //***************************************
  // Dispatcher Execution
  // Enumerated: defines all stages of TTasks
  TStage = (
    Stage_To_Be_Started = 1,
    Stage_GetPart,
    Stage_Unload,
    Stage_To_AR_Out,
    Stage_Clear_Pos_AR,
    Stage_Finished,

    // --- Novos estados para INBOUND ---
    Stage_Req_Inbound,          // Pede a matéria-prima (M_Do_Inbound)
    Stage_Wait_Inbound_Tapete,  // Espera que chegue ao tapete de entrada
    Stage_Find_Free_AR,         // Procura posição livre na matriz WAREHOUSE_Parts
    Stage_Load_AR,              // Carrega para o armazém (M_Load)

    // --- Novos estados para PRODUÇÃO ---
    Stage_Wait_AR_Out_Prod,     // Espera que a MP chegue ao tapete de saída
    Stage_Req_Production,       // Envia para a célula (M_Do_Production)
    Stage_Wait_Prod_Return      // Espera que o produto final volte ao tapete de entrada
  );

  // Data structure for holding one Task (OE, OD, OP)
  TTask = record
   task_type           : TTask_Type; // type
   current_operation   : TStage;     // the stage that is currently activ.
   part_type           : Integer;    // Part type { 0, ... 9}
   part_position_AR    : Integer;    // Part Position in AR (if needed)
   part_destination    : Integer;    // Part destination
  end;

  TArray_Task = array of TTask;      // NOTE: this "type" will originate a variable to hold the output from the scheduling ("sequenciador").
  //***************************************


  //***************************************
  // Availability of the resources in the shopfloor:
  TResources = record
   AR_free      : Boolean;    // true (free) or false (busy)
   AR_In_Part   : integer;    // Com uma peça do tipo P={0..9} (0=sem peça)
   AR_Out_Part  : integer;    // Com uma peça do tipo P={0..9} (0=sem peça)
   Robot_1_Part : integer;    // Com uma peça do tipo P={0..9} (0=sem peça)
   Robot_2_Part : integer;    // Com uma peça do tipo P={0..9} (0=sem peça)
   Inbound_free : Boolean;    // true (free) or false (busy)
  end;
  //***************************************


  { TFormDispatcher }
  TFormDispatcher = class(TForm)
    BStart: TButton;
    BExecute: TButton;
    BInitiatilize: TButton;
    btnAddAprov: TButton;
    btnAddProd: TButton;
    btnAddExp: TButton;
    btnInicializarArmazem: TButton;
    btnExecutar: TButton;
    btnLimpar: TButton;
    btnExtrairRelatorio: TButton;
    btnAdicionarDefeito: TButton;
    btnDefeitosLimpar: TButton;
    btnDefeitoConfirmar: TButton;
    cbCorProd: TComboBox;
    cbCorExp: TComboBox;
    cbProduto: TComboBox;
    cbCorAprov: TComboBox;
    cbProdProd: TComboBox;
    cbProdExp: TComboBox;
    cbTipoDefeito: TComboBox;
    cbCorDefeito: TComboBox;
    GroupBox1: TGroupBox;
    GroupBox10: TGroupBox;
    GroupBox11: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    GroupBox6: TGroupBox;
    GroupBox7: TGroupBox;
    GroupBox8: TGroupBox;
    GroupBox9: TGroupBox;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    Image5: TImage;
    Image6: TImage;
    Image7: TImage;
    imgLogo: TImage;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    Label28: TLabel;
    Label29: TLabel;
    Label30: TLabel;
    Label31: TLabel;
    Label32: TLabel;
    Label33: TLabel;
    Label34: TLabel;
    Label35: TLabel;
    Label36: TLabel;
    Label37: TLabel;
    Label38: TLabel;
    Label39: TLabel;
    Label40: TLabel;
    lblCustoTotal: TLabel;
    lblEmProcessamento: TLabel;
    lblTapeteInbound: TLabel;
    lblTapeteEntradaAR: TLabel;
    lblTapeteSaidaAR: TLabel;
    lblEstadoCel2: TLabel;
    lblPecaCel2: TLabel;
    lblEstadoCel1: TLabel;
    lblPecaCel1: TLabel;
    lblScadaLotacao: TLabel;
    lblScadaTempoBraco: TLabel;
    lblScadaTempoPlano: TLabel;
    lblArmazemBaseAzul: TLabel;
    lblArmazemBaseCinza: TLabel;
    lblArmazemBaseVerde: TLabel;
    lblArmazemMatAzul: TLabel;
    lblArmazemMatCinza: TLabel;
    lblArmazemMatVerde: TLabel;
    lblArmazemTampaAzul: TLabel;
    lblArmazemTampaCinza: TLabel;
    lblArmazemTampaVerde: TLabel;
    lblScadaUtilizacao: TLabel;
    labelRelogio: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lblTempoAR: TLabel;
    lblTempoCell1: TLabel;
    lblTempoCell2: TLabel;
    lblTempoEsperaAR: TLabel;
    lblTempoInbound: TLabel;
    lblTotalExpedidas: TLabel;
    lblTotalRecebidas: TLabel;
    lstDefeito: TListBox;
    lstPlano: TListBox;
    memLogger: TMemo;
    PageControl1: TPageControl;
    Header: TPanel;
    Footer: TPanel;
    PageControl2: TPageControl;
    PageControlTarefas: TPageControl;
    panelProducao: TPanel;
    panelArmazem: TPanel;
    pnlRelogio: TPanel;
    btnPLC: TSpeedButton;
    Shape1: TShape;
    Shape2: TShape;
    Shape3: TShape;
    Shape4: TShape;
    Shape5: TShape;
    Shape6: TShape;
    Shape7: TShape;
    shpLedCel1: TShape;
    shpLedCel2: TShape;
    shpStatusBraco: TShape;
    shpStatusPLC: TShape;
    spnQuantidadeDefeito: TSpinEdit;
    spnMatAzul: TSpinEdit;
    spnMatVerde: TSpinEdit;
    spnMatCinza: TSpinEdit;
    spnBaseAzul: TSpinEdit;
    spnBaseVerde: TSpinEdit;
    spnBaseCinza: TSpinEdit;
    spnQtdAprov: TSpinEdit;
    spnQtdProd: TSpinEdit;
    spnQtdExp: TSpinEdit;
    spnTampaAzul: TSpinEdit;
    spnTampaVerde: TSpinEdit;
    spnTampaCinza: TSpinEdit;
    StaticText1: TStaticText;
    StaticText2: TStaticText;
    StringGrid1: TStringGrid;
    sgArmazem: TStringGrid;
    TabSheet1: TTabSheet;
    TabSheet10: TTabSheet;
    TabSheet11: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet5: TTabSheet;
    TabSheet6: TTabSheet;
    TabSheet7: TTabSheet;
    Expedicao: TTabSheet;
    TabSheet8: TTabSheet;
    TabSheet9: TTabSheet;
    Timer1: TTimer;
    procedure BExecuteClick(Sender: TObject);
    procedure BInitiatilizeClick(Sender: TObject);
    procedure BStartClick(Sender: TObject);
    procedure btnAddAprovClick(Sender: TObject);
    procedure btnAddExpClick(Sender: TObject);
    procedure btnAddProdClick(Sender: TObject);
    procedure btnExecutarClick(Sender: TObject);
    procedure btnExtrairRelatorioClick(Sender: TObject);
    procedure btnInicializarArmazemClick(Sender: TObject);
    procedure btnLimparClick(Sender: TObject);
    procedure btnPLCClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure sgArmazemDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure Shape7Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure btnAdicionarDefeitoClick(Sender: TObject);
    procedure btnDefeitosLimparClick(Sender: TObject);
    procedure btnDefeitoConfirmarClick(Sender: TObject);
  private
  public
    procedure Dispatcher(var tasks:TArray_Task; {var idx : integer;} shopfloor: TResources );    //Comentado para fazer mais que uma tarefa ao mesmo tempo
    procedure Execute_Expedition_Order(var task:TTask; shopfloor: TResources );

    procedure Execute_Delivery_Order(var task:TTask; shopfloor: TResources ); //inbound dispacher

    procedure Execute_Production_Order(var task:TTask; shopfloor: TResources ); //Production

    procedure LogMsg(Texto: string); //Logger para aparecer as horas

    procedure Atualizar_SCADA_Armazem; // Interface Contagem de Peças

    function GET_AR_Position (Part : integer; Warehouse : array of integer): integer;
    procedure SET_AR_Position (idx : integer; Part : integer; var Warehouse : array of integer);

    procedure UpdateMachineTimers(shopfloor: TResources);

    procedure Atualizar_Custos; // Nova função de dinheiro

    function Contar_Cinzentos_Em_Circulacao: integer; // Checa os cinzentos

    function Tem_Expedicao_Verde_Pendente: boolean; // O nosso bloqueador

    // NOVAS FUNÇÕES DO SISTEMA DE PONTUAÇÃO
    function IsReplenishment(const order: TProduction_Order; const allOrders: TArray_Production_Order): Boolean;
    function GetOrderPriority(const order: TProduction_Order): Integer;
    procedure SmartSortOrders(var orders: TArray_Production_Order);

    //Scada Estantes Armazem
    function TraduzirPeca(codigo: integer): string;
    procedure Atualizar_Matriz_Armazem;

    procedure Atualizar_SCADA_Modular; //Sinotico scada

  end;

const
  //ID for Parts to be used by FIO
  Part_Raw_Blue   = 1;
  Part_Raw_Green  = 2;
  Part_Raw_Grey   = 3;
  Part_Base_Blue  = 4;
  Part_Base_Green = 5;
  Part_Base_Grey  = 6;
  Part_Lid_Blue   = 7;
  Part_Lid_Green  = 8;
  Part_Lid_Grey   = 9;


(* GLOBAL VARIABLES *)
var
  FormDispatcher : TFormDispatcher;

  // Production orders obtained by the ERP (using the SQL Query)
  Production_Orders : TArray_Production_Order;

  // Availability of resources (needs to be updated over time)
  ShopResources : TResources;

  // Tasks that need to be concluded by the MES (expedition, delivery, production and trash).
  ShopTasks     : TArray_Task;

  // Index of the task (from the array "ShopTasks") that is being executed.
  idx_Task_Executing : integer;

  // Status of each cell in the warehouse.
  WAREHOUSE_Parts           : array of integer;         //warehouse parts in each position

  //Variáveis de Contagem
  Total_Recebidas : integer = 0;
  Total_Expedidas : integer = 0;
  Em_Processamento : integer = 0;

  // Cronómetro Mestre do Plano - Braço Robótico
  Plano_A_Executar : Boolean = False;
  Tempo_Inicio_Plano : TDateTime;
  Tempo_Total_Plano_Seg : Double = 0;


  // Contadores persistentes de produção por tipo de peça
  Prod_BaseAzul   : integer = 0;
  Prod_BaseVerde  : integer = 0;
  Prod_BaseCinza  : integer = 0;
  Prod_TampaAzul  : integer = 0;
  Prod_TampaVerde : integer = 0;
  Prod_TampaCinza : integer = 0;


  // MÉTRICAS 3.5 — Tempo acumulado de operação por máquina
  AR_Op_Start      : TDateTime;   // Momento em que o AR ficou ocupado
  AR_Op_Total      : Double;      // Segundos acumulados de operação do AR
  AR_Was_Busy      : Boolean;     // Flag: estava ocupado no ciclo anterior?

  Inbound_Op_Start : TDateTime;
  Inbound_Op_Total : Double;
  Inbound_Was_Busy : Boolean;

  Cell1_Op_Start   : TDateTime;
  Cell1_Op_Total   : Double;
  Cell1_Was_Busy   : Boolean;     // Robot_1_Part > 0 → célula 1 em operação

  Cell2_Op_Start   : TDateTime;
  Cell2_Op_Total   : Double;
  Cell2_Was_Busy   : Boolean;     // Robot_2_Part > 0 → célula 2 em operação

  // MÉTRICAS 3.6 — Tempo médio de espera à entrada do armazém
  AR_Wait_Start   : TDateTime;   // Início do episódio de espera atual
  AR_Wait_Total   : Double;      // Soma de todos os tempos de espera (segundos)
  AR_Wait_Count   : Integer;     // Número de episódios de espera registados
  AR_Part_Waiting : Boolean;     // Flag: havia peça à espera no ciclo anterior?

  // --- Variáveis para Custos ---
  Inbound_MP_Azul  : integer = 0;
  Inbound_MP_Verde : integer = 0;
  Inbound_MP_Cinza : integer = 0;
  Total_Defeitos   : integer = 0; //- NOTA confirmar se está a funcionar

  // Variável para evitar que duas tarefas roubem a mesma peça na entrada
  Entrada_AR_Reclamada: Boolean = False;

  // Última leitura Modbus (espelho para o separador SCADA)
  LastPLCStatus: status_values;


implementation

{$R *.lfm}


//******************************************************************************
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//******************************************************************************


//----------- CÓDIGO INATIVO - ALPENAS POR UMA QUESTÃO DE SEGURANÇA ------------


//CÓDIGO NÃO UTILIZADO POIS O BOTÃO ESTÁ INATIVO - APENAS AQUI POR UMA QUESTÃO DE SEGURANÇA EM CASO DE BUG
//HARD CODE

// Query DB -> Scheduling -> Connect PLC for Dispatching
procedure TFormDispatcher.BStartClick(Sender: TObject);
var
    result           : integer;
    production_order : TProduction_Order;
begin
  // ******************************************
  // Query to DB and converts data to structures
  // ...      to be completed by the STUDENT after SQL introduction in INFI.
  // *****************************************
  // ******************************************
  // Simulating the result of the SQL query:
  // CENÁRIO COMPLETO DO VÍDEO DA ENTREGA

  SetLength(Production_Orders, 7); // Precisamos de 7 posições no array

  // 1. A produção de uma tampa cinzenta
  production_order.order_type   := Type_Production;
  production_order.part_numbers := 1;
  production_order.part_type    := Part_Lid_Grey;    // Tampa Cinzenta (9)
  Production_Orders[0]          := production_order;

  // 2. A produção de uma tampa verde
  production_order.order_type   := Type_Production;
  production_order.part_numbers := 1;
  production_order.part_type    := Part_Lid_Green;   // Tampa Verde (8)
  Production_Orders[1]          := production_order;

  // 3. A produção de uma base azul
  production_order.order_type   := Type_Production;
  production_order.part_numbers := 1;
  production_order.part_type    := Part_Base_Blue;   // Base Azul (4)
  Production_Orders[2]          := production_order;

  // 4. A expedição de uma tampa verde
  production_order.order_type   := Type_Expedition;
  production_order.part_numbers := 1;
  production_order.part_type    := Part_Lid_Green;   // Tampa Verde (8)
  Production_Orders[3]          := production_order;

  // 5. A expedição de uma base azul
  production_order.order_type   := Type_Expedition;
  production_order.part_numbers := 1;
  production_order.part_type    := Part_Base_Blue;   // Base Azul (4)
  Production_Orders[4]          := production_order;

  // 6. O aprovisionamento de 1 matéria-prima azul
  production_order.order_type   := Type_Delivery;
  production_order.part_numbers := 1;
  production_order.part_type    := Part_Raw_Blue;    // MP Azul (1)
  Production_Orders[5]          := production_order;

  // 7. O aprovisionamento de 1 matéria-prima cinzenta
  production_order.order_type   := Type_Delivery;
  production_order.part_numbers := 1;
  production_order.part_type    := Part_Raw_Grey;    // MP Cinzenta (3)
  Production_Orders[6]          := production_order;

  // ******************************************

  // Simulating the result of the SQL query:
  (*SetLength(Production_Orders, 1);                   //Let's create only some Orders to use as an example. STUDENT MUST CHANGE ACCORDING TO REQUIREMENTS

  //Expedition
  production_order.order_type   := Type_Expedition ;
  production_order.part_numbers := 2;
  production_order.part_type    := Part_Base_Blue;    //Blue Base
  Production_Orders[0]          := production_order;  //Saving..

  production_order.order_type   := Type_Expedition ;  //Expedition
  production_order.part_numbers := 2;
  production_order.part_type    := Part_Lid_Green;    //Green Lids
  Production_Orders[1]          := production_order;  //Saving..


  production_order.order_type     := Type_Delivery ;    //Inbounds
  production_order.part_numbers   := 1;
  production_order.part_type      := 2;                    //Green Raw Material
  Production_Orders[1]            := production_order;

  production_order.order_type     := Type_Production;   //Production
  production_order.part_numbers   := 1;
  production_order.part_type      := 4;                    //Blue Base
  Production_Orders[2]            := production_order;

  production_order.order_type     := Type_Expedition;   //Expedition
  production_order.part_numbers   := 1;
  production_order.part_type      := 4;                    //Green Base
  Production_Orders[4]            := production_order;
  *)
  // ******************************************
  // for Scheduling
  idx_Task_Executing := 0;
  //Connecting to PLC
  result := M_connect();

  if (result = 1) then
    BStart.Caption:='Connected to PLC'
  else
  begin
    BStart.Caption:='Start';
    ShowMessage('PLC unavailable. Please try again!');
   end;
end;


//BOTÃO NÃO É USADO - APENAS AQUI POR MOTIVOS DE SEGURANÇA EM CASO DE BUGS
//Botão Adicionar
{Botão antigo
procedure TFormDispatcher.btnAddAprovClick(Sender: TObject);
var
  tarefa, peca, produto, cor: string;
  qtd: integer;
begin
  // 1. Descobrir o Tipo de Tarefa lendo o título do separador (Tab) que está aberto
  if PageControlTarefas.ActivePage <> nil then
    tarefa := PageControlTarefas.ActivePage.Caption
  else
  begin
    ShowMessage('Erro: Nenhum separador selecionado.');
    Exit;
  end;

  // 2. Verificar se o utilizador selecionou o Produto e a Cor
  if (cbProduto.ItemIndex = -1) or (cbCorAprov.ItemIndex = -1) then
  begin
    ShowMessage('Por favor, selecione o Produto e a Cor!');
    Exit;
  end;

  produto := cbProduto.Text;
  cor := cbCorAprov.Text;

  // O TRUQUE MÁGICO: Juntamos as duas palavras para o botão Executar não se queixar!
  peca := produto + ' ' + cor; // Ex: "Matéria" + " " + "Azul" = "Matéria Azul"

  qtd := spnQtdAprov.Value;

  if qtd <= 0 then
  begin
    ShowMessage('A quantidade a adicionar tem de ser pelo menos 1!');
    Exit;
  end;

  // 3. AS MESMAS VALIDAÇÕES INDUSTRIAIS DE SEGURANÇA
  if (tarefa = 'Aprovisionamento') and (produto <> 'Matéria') then
  begin
     ShowMessage('Erro: O Aprovisionamento só recebe Matérias-Primas!');
     Exit;
  end;

  if (tarefa = 'Produção') and (produto = 'Matéria') then
  begin
     ShowMessage('Erro: As Matérias-Primas não podem ser produzidas!');
     Exit;
  end;

  if (tarefa = 'Expedição') and (produto = 'Matéria') then
  begin
     ShowMessage('Erro: Só pode expedir produtos finais (Bases ou Tampas).');
     Exit;
  end;

  // 4. Tudo válido! Adicionar à ListBox com a exata mesma formatação de antes
  lstPlano.Items.Add(tarefa + ' | ' + peca + ' | ' + IntToStr(qtd));

  LogMsg('SISTEMA: Adicionado ao plano -> ' + tarefa + ' de ' + IntToStr(qtd) + 'x ' + peca);
end; }


//CÓDIGO NÃO É USADO POIS O BOTÃO FOI DESATIVADO, SERVE APENAS NO CASO DE HAVER ALGUM BUG
//HARD CODE


//Initialization of the MES /week. This procedure run only once per week
procedure TFormDispatcher.BInitiatilizeClick(Sender: TObject);
var
    cel, r: integer;
begin
  // *********************************************************
  // WAREHOUSE MANAGEMENT

  // Inicialização de acordo com o cenário do Guião:
  r := M_Initialize(1, Part_Raw_Blue);      // 1 Matéria-prima azul na pos 1
  sleep(1500);
  r := r + M_Initialize(10, Part_Raw_Green);// 1 Matéria-prima verde na pos 10
  sleep(1500);
  r := r + M_Initialize(19, Part_Raw_Grey); // 1 Matéria-prima cinzenta na pos 19
  sleep(1500);
  r := r + M_Initialize(28, Part_Lid_Green);// 1 Tampa verde na pos 28

  if( r > 4) then
    LogMsg('Innitiatialization with errors');

  // Update the Warehouse according to the previous innitialization
  SetLength(WAREHOUSE_Parts, 55);                // Parts in the warehouse
  for cel := 1 to Length(WAREHOUSE_Parts)-1 do
  begin
      WAREHOUSE_Parts[cel] := 0;
  end;

  // Registar as peças nas respetivas posições para a nossa matriz lógica
  WAREHOUSE_Parts[1]  := Part_Raw_Blue;
  WAREHOUSE_Parts[10] := Part_Raw_Green;
  WAREHOUSE_Parts[19] := Part_Raw_Grey;
  WAREHOUSE_Parts[28] := Part_Lid_Green;


  //Converts ProductionOrders to Tasks (staged activities)
  //SimpleScheduler(Production_Orders, ShopTasks); NÃO DEVIA ESTAR COMENTADO MAS DEU ERRO TALVEZ POR ESTAR ANTES DA PROCEDURE


  // Starting Dispatcher Iterations over time
  Timer1.Enabled:= true;
end;


//--------------------------- FIM DO CÓDIGO INATIVO ----------------------------


//******************************************************************************
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//******************************************************************************


//---------------------- PROCEDURES PRÉ-FEITAS PROFESSOR -----------------------


{ Procedure that checks the status of the resources available on the shop floor }
procedure UpdateResources(var shopfloor: TResources);
var
    resp : status_values;
begin
  {'FactoryIO state',
   'Inbound state',
   'Warehouse_state',
   'Warehouse input conveyor part',
   'Warehouse output conveyor part',
   'Cell 1 part',
   'Cell 2 part',
   'Pick & Place part'
   }
  resp := M_Get_Factory_Status();
  LastPLCStatus := resp;

  with shopfloor do
  begin
    Inbound_free := resp[2] = 1;
    AR_free      := resp[3] = 1;
    AR_In_Part   := resp[4];
    AR_Out_Part  := resp[5];
    Robot_1_Part := resp[6];
    Robot_2_Part := resp[7];
  end;
end;


{ Procedure that received TArray_Production_Order and converts to TArray_Task
-> INPUT: TArray_Production_Order
-> OUTPUT: TArray_Task
}
procedure SimpleScheduler(var orders: TArray_Production_Order; var tasks:TArray_Task );
var
    current_task     : TTask;
    idx_order        : integer;
    numb_tasks_total : integer = 0;       // total number of tasks created in "tasks"
    numb_same_task   : integer = 0;

begin
  for idx_order:= 0 to Length(orders)-1 do
  begin
      with current_task do
      begin
        numb_same_task    := 0;

        task_type         := orders[idx_order].order_type;
        part_type         := orders[idx_order].part_type;
        current_operation := Stage_To_Be_Started;

        part_position_AR  := -1;  // to be defined later.   STUDENTS MUST CHANGE

        if( part_type < Part_Lid_Blue )then
        begin
             part_destination  := 1;     // if bases (Exit 1 or Cell 1)
        end else
        begin
            part_destination  := 2;     // if bases (Exit 2 or Cell 2)
        end;
        //Create  orders[idx_order].part_numbers of the same TTask for Dispatcher.
        numb_tasks_total :=  Length(tasks);
        SetLength(tasks,  numb_tasks_total + orders[idx_order].part_numbers);
        for numb_same_task := 0 to orders[idx_order].part_numbers-1 do
        begin
            tasks[numb_tasks_total+numb_same_task] := current_task;
        end;
      end;
  end;

end;


procedure TFormDispatcher.FormCreate(Sender: TObject);
begin
  SetLength(ShopTasks, 0);
  idx_Task_Executing := 0;
  Self.DoubleBuffered := True;
end;

procedure TFormDispatcher.sgArmazemDrawCell(Sender: TObject; aCol,
  aRow: Integer; aRect: TRect; aState: TGridDrawState);
var
  Texto: string;
  IDPeca: integer;
  i_array: integer;
  Estilo: TTextStyle;
begin
  // 1. Converter a coordenada visual (invertida) de volta para o índice do array (1..54)
  // row 5 (fundo visual) -> nível 1 do armazém (i=1..9)
  // Matemática invertida: (8 - aCol) faz o espelho horizontal da direita para a esquerda!
  i_array := ((5 - aRow) * 9) + (8 - aCol) + 1;

  // 2. NOVA PROTEÇÃO DE MEMÓRIA (O "Escudo" contra o Access Violation)
  if Length(WAREHOUSE_Parts) = 0 then
  begin
    // Se o array ainda não tem tamanho, o programa acabou de abrir.
    IDPeca := 0;
  end
  else if (i_array >= 1) and (i_array <= 54) then
  begin
     // O array já foi criado e o índice é válido!
     IDPeca := WAREHOUSE_Parts[i_array];
  end
  else
  begin
     // Prevenção extra de segurança
     IDPeca := 0;
  end;

  // Traduzir o número para o texto que vai aparecer no ecrã
  Texto := TraduzirPeca(IDPeca);

  // 3. O SISTEMA DE CORES (OwnerDraw)
  case IDPeca of
    0: // Vazio - Fundo Branco, Texto Cinza Suave
    begin
      sgArmazem.Canvas.Brush.Color := clWhite;
      sgArmazem.Canvas.Font.Color := clSilver;
      sgArmazem.Canvas.Font.Style := [];
    end;

    Part_Raw_Grey: // Matéria Cinza - Fundo Cinza Claro, Texto Preto
    begin
      sgArmazem.Canvas.Brush.Color := clLtGray;
      sgArmazem.Canvas.Font.Color := clBlack;
      sgArmazem.Canvas.Font.Style := [];
    end;

    Part_Lid_Green, Part_Base_Green: // Peças Verdes Prontas - Fundo Verde Suave, Texto Verde
    begin
      sgArmazem.Canvas.Brush.Color := $DDFFDD; // Verde muito claro (código hexadecimal)
      sgArmazem.Canvas.Font.Color := clGreen;
      sgArmazem.Canvas.Font.Style := [fsBold]; // Letras a negrito
    end;

    Part_Raw_Green: // Matéria Verde - Fundo Verde Suave, Texto Preto
    begin
      sgArmazem.Canvas.Brush.Color := $EEFFEE;
      sgArmazem.Canvas.Font.Color := clBlack;
      sgArmazem.Canvas.Font.Style := [];
    end;

    // Peças Azuis (MP ou Prontas)
    Part_Raw_Blue, Part_Base_Blue, Part_Lid_Blue:
    begin
      sgArmazem.Canvas.Brush.Color := $FFEEEE; // Azul muito claro
      sgArmazem.Canvas.Font.Color := clBlue;
      sgArmazem.Canvas.Font.Style := [];
    end;

    // Estados de Movimentação (reservas)
    -1: // A Entrar (Inbound) - Fundo Amarelo, Texto Preto
    begin
      sgArmazem.Canvas.Brush.Color := clYellow;
      sgArmazem.Canvas.Font.Color := clBlack;
      sgArmazem.Canvas.Font.Style := [];
    end;
    -2: // A Sair (Expedição/Produção) - Fundo Laranja (Atenção), Texto Preto
    begin
      sgArmazem.Canvas.Brush.Color := TColor($008CFF); // Cor Laranja Industrial (Darkorange)
      sgArmazem.Canvas.Font.Color := clBlack;
      sgArmazem.Canvas.Font.Style := [];
    end;
    else
    begin
      // Peças não definidas ainda, ou erros - Default
      sgArmazem.Canvas.Brush.Color := clWhite;
      sgArmazem.Canvas.Font.Color := clBlack;
      sgArmazem.Canvas.Font.Style := [];
    end;
  end;

  // 4. Desenhar Efetivamente (OwnerDraw)

  // Desenhar o background da célula (FillRect)
  sgArmazem.Canvas.FillRect(aRect);

  // O TRUQUE DO LAZARUS: Copiar, alterar e devolver!
  Estilo := sgArmazem.Canvas.TextStyle; // Tira uma cópia do estilo atual
  Estilo.Alignment := taCenter;         // Centra na horizontal
  Estilo.Layout := tlCenter;            // Centra na vertical
  sgArmazem.Canvas.TextStyle := Estilo; // Devolve o estilo corrigido ao Canvas

  // Desenhar o texto centralizado no quadrado
  sgArmazem.Canvas.TextRect(aRect, aRect.Left, aRect.Top, Texto);

  // Desenhar uma borda fina cinza para simular a prateleira
  sgArmazem.Canvas.Pen.Color := clSilver;
  sgArmazem.Canvas.Frame(aRect);
end;

procedure TFormDispatcher.Shape7Click(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet10;

end;



procedure TFormDispatcher.Timer1Timer(Sender: TObject);
var
  TodasConcluidas: boolean; // AS VARIÁVEIS TÊM DE FICAR AQUI EM CIMA!
  i: integer;
begin
  // RELÓGIO DA UI (Corre sempre, independentemente do PLC)
  labelRelogio.Caption := FormatDateTime('hh:nn:ss', Now);

  // Se o botão ainda diz "CONECTAR PLC", o código pára aqui e sai da procedure.
  if btnPLC.Caption = 'CONECTAR PLC' then
  begin
    Exit;
  end;

  BExecuteClick(Self);


  Atualizar_SCADA_Armazem; //Atualiza a cada segundo o armazem

  Atualizar_Matriz_Armazem; // MATRIZ VISUAL EM TEMPO REAL!

  Atualizar_SCADA_Modular; //Atualiza em tempo real o novo scada

  UpdateMachineTimers(ShopResources);// Atualiza os cronómetros
  Atualizar_Custos; //O Custo sobe em tempo real!

  // --- NOVO TRAVÃO DE FIM DE TURNO MULTI-TAREFA ---
  if Length(ShopTasks) > 0 then
  begin
    // Vamos assumir que todas acabaram, e tentamos provar o contrário
    TodasConcluidas := True;

    for i := 0 to Length(ShopTasks) - 1 do
    begin
      if ShopTasks[i].current_operation <> Stage_Finished then
      begin
        TodasConcluidas := False; // Encontrámos uma que ainda está a andar!
        Break;
      end;
    end;

    // Se confirmarmos que todas estão realmente no Stage_Finished:
    if TodasConcluidas then
    begin
      Timer1.Enabled := False; // Pára o relógio da fábrica

      // Pára o cronómetro dos kpis
      Plano_A_Executar := False;

      LogMsg('SISTEMA: Plano Semanal concluído! A aguardar Validação de Qualidade.');
      ShowMessage('Fim do Plano Semanal!' + sLineBreak + 'Por favor, valide a qualidade das peças produzidas no separador Monitorização.');

      // Limpa a lista de tarefas
      SetLength(ShopTasks, 0);

      // Muda o ecrã automaticamente para o separador da grelha
      PageControl1.ActivePage := TabSheet2;
    end;
  end;
end;


// get the first position (cell) in AR that contains the "Part" (Procura em Leque Otimizada)
function TFormDispatcher.GET_AR_Position (Part : integer; Warehouse : array of integer): integer;
const
  // A Rota do Leque: As 54 posições ordenadas da mais próxima (1) para a mais distante (54)
  Ordem_Leque: array[1..54] of integer = (
    1,
    2, 10,
    3, 11, 19,
    4, 12, 20, 28,
    5, 13, 21, 29, 37,
    6, 14, 22, 30, 38, 46,
    7, 15, 23, 31, 39, 47,
    8, 16, 24, 32, 40, 48,
    9, 17, 25, 33, 41, 49,
    18, 26, 34, 42, 50,
    27, 35, 43, 51,
    36, 44, 52,
    45, 53,
    54
  );
var
  k, pos_real : integer;
begin
  Result := 0; // Garante que devolve 0 se não encontrar nada

  // Em vez de varrer do 1 ao 54 cegamente, varre seguindo a nossa rota!
  for k := 1 to 54 do
  begin
    pos_real := Ordem_Leque[k];

    // Proteção: só lê se a posição existir fisicamente na matriz WAREHOUSE_Parts
    if pos_real < Length(Warehouse) then
    begin
      if Warehouse[pos_real] = Part then
      begin
        Result := pos_real; // Encontrou a peça (ou o espaço vazio) mais próximo!
        Exit;
      end;
    end;
  end;
end;


//Sets the Position of the AR with the "Part" provided
procedure TFormDispatcher.SET_AR_Position (idx : integer; Part : integer; var Warehouse : array of integer);
begin
  Warehouse [ idx ] := Part;
end;


procedure TFormDispatcher.BExecuteClick(Sender: TObject);
begin
  // See the availability of resources
  UpdateResources(ShopResources);
  //Dispatcher executing per cycle.
  if(Length(ShopTasks)>0) then begin
    Dispatcher(ShopTasks, {idx_Task_Executing,} ShopResources);  //Multitarefas
  end;
end;


//-------------------- FIM PROCEDURES PRÉ-FEITAS PROFESSOR ---------------------


//******************************************************************************
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//******************************************************************************


//---------------------- CÓDIGO INTERNO - ALTERADO/FEITO -----------------------

 {
// Global Dispatcher - SIMPLEX
procedure TFormDispatcher.Dispatcher(var tasks:TArray_Task; var idx : integer; shopfloor: TResources );
begin
    case tasks[idx].task_type of

      // Expedition
      Type_Expedition :
      begin
        if(idx < Length(tasks)) then
        begin
          LogMsg('Task Expedition');
          Execute_Expedition_Order(tasks[idx], shopfloor);

          // Next Operation to be executed.
          if(tasks[idx].current_operation = Stage_Finished) then
            inc(idx_Task_Executing);
        end;
      end;


      // Production
      Type_Production :
      begin
        if(idx < Length(tasks)) then
        begin
          LogMsg('Task Production');

          Execute_Production_Order(tasks[idx], shopfloor);

          if(tasks[idx].current_operation = Stage_Finished) then
            inc(idx_Task_Executing);
        end;
      end;


      // Inbound
      Type_Delivery :
      begin
        if(idx < Length(tasks)) then
        begin
          LogMsg('Task Inbound/Delivery');

          // Chama o procedimento
          Execute_Delivery_Order(tasks[idx], shopfloor);

          // Verifica se a tarefa já acabou. Se sim, avança para a próxima da lista.
          if(tasks[idx].current_operation = Stage_Finished) then
            inc(idx_Task_Executing);
        end;
      end;

      // Trash
      Type_Trash :
      begin
        //todo
      end;

    end;
end;
  }

// Global Dispatcher - MULTI-TAREFA (Paralelismo)
procedure TFormDispatcher.Dispatcher(var tasks:TArray_Task; shopfloor: TResources );
var
  i: integer;
begin
  // Percorre TODA a lista de tarefas, do início ao fim, a cada milissegundo!
  for i := 0 to Length(tasks) - 1 do
  begin
    // Se esta tarefa específica já chegou ao fim da sua viagem, ignoramos e passamos à próxima
    if tasks[i].current_operation = Stage_Finished then
      Continue;

    // Se ainda não acabou, tenta executá-la (os nossos "semáforos" lá dentro decidem se ela avança ou fica à espera)
    case tasks[i].task_type of
      Type_Expedition : Execute_Expedition_Order(tasks[i], shopfloor);
      Type_Production : Execute_Production_Order(tasks[i], shopfloor);
      Type_Delivery   : Execute_Delivery_Order(tasks[i], shopfloor);
    end;
  end;
end;

// Procedimento que executa uma ordem de Produção
procedure TFormDispatcher.Execute_Production_Order(var task:TTask; shopfloor: TResources );
var
    r : integer;
    raw_material_needed : integer;
begin
  // Primeiro, temos de saber qual é a matéria-prima (MP) a ir buscar ao armazém
  // Baseando-nos no produto final que o "part_type" nos pede.
  case task.part_type of
    Part_Base_Blue, Part_Lid_Blue:   raw_material_needed := Part_Raw_Blue;    // Precisa MP Azul (1)
    Part_Base_Green, Part_Lid_Green: raw_material_needed := Part_Raw_Green;   // Precisa MP Verde (2)
    Part_Base_Grey, Part_Lid_Grey:   raw_material_needed := Part_Raw_Grey;    // Precisa MP Cinzenta (3)
    else raw_material_needed := 0;
  end;

  with task do
  begin
     case current_operation of

        // --- FASE 1: Iniciar. Anunciar a ordem e passar para a procura ---
        Stage_To_Be_Started:

        //semaforo
        begin
           // 1. Regra dos Cinzentos
           if ((part_type = Part_Base_Grey) or (part_type = Part_Lid_Grey)) and
              (Contar_Cinzentos_Em_Circulacao > 0) then
             Exit;

           LogMsg('PRODUÇÃO: Iniciar peça ' + IntToStr(part_type) + '. A procurar MP ' + IntToStr(raw_material_needed));
           current_operation := Stage_GetPart;
        end;

        // --- FASE 2: Procurar a MP no armazém ---
        Stage_GetPart :
        begin
          if(shopfloor.AR_free) then
          begin
            part_position_AR := GET_AR_Position(raw_material_needed, WAREHOUSE_Parts);
            if( part_position_AR > 0 ) then
            begin
               LogMsg('PRODUÇÃO: MP encontrada na posição ' + IntToStr(part_position_AR));
               // RESERVA DE SAÍDA! (-2 significa "A ser removida")
               SET_AR_Position(part_position_AR, -2, WAREHOUSE_Parts);
               current_operation :=  Stage_Unload;
            end
            else
               LogMsg('AVISO PRODUÇÃO: A aguardar MP ' + IntToStr(raw_material_needed) + ' no armazém...');
          end;
        end;

        // --- FASE 3: Descarregar a MP ---
        Stage_Unload :
        begin
          if (ShopResources.AR_free) and (ShopResources.AR_Out_Part = 0) then
          begin
            r := M_Unload(part_position_AR);
            if ( r = 1 ) then
            begin
               ShopResources.AR_free := False; // Tranca o braço
               LogMsg('PRODUÇÃO: A descarregar MP...');

               // A peça saiu fisicamente! Agora sim, o lugar fica vazio (0)
               SET_AR_Position(part_position_AR, 0, WAREHOUSE_Parts);

               current_operation := Stage_Wait_AR_Out_Prod;
            end;
          end;
        end;

        // --- FASE 4: Esperar que a MP chegue ao tapete de saída ---
        Stage_Wait_AR_Out_Prod :
        begin
          // A peça tem de estar no tapete de saída antes de enviarmos para a máquina
          if( ShopResources.AR_Out_Part = raw_material_needed ) then
          begin
             LogMsg('PRODUÇÃO: MP no tapete de saída. A enviar para célula ' + IntToStr(part_destination));
             current_operation := Stage_Req_Production;
          end;
        end;

        // --- FASE 5: Enviar para a Máquina de Produção ---
        Stage_Req_Production:
        begin
          r := M_Do_Production(part_destination);
          if (r = 1) then
          begin
             LogMsg('PRODUÇÃO: A processar na máquina. A aguardar regresso...');
             Inc(Em_Processamento);

             // ATENÇÃO: APAGUEI O SET_AR_Position DAQUI PARA NÃO APAGAR PEÇAS NOVAS!

             current_operation := Stage_Wait_Prod_Return;
          end;
        end;

        // --- FASE 6: Esperar que o Produto Final regresse à entrada ---
        Stage_Wait_Prod_Return:
        begin
          // NOVA REGRA: A peça é da minha cor E ninguém a reclamou ainda?
          if (ShopResources.AR_In_Part = part_type) and (not Entrada_AR_Reclamada) then
          begin
             Entrada_AR_Reclamada := True; // Tira a senha! "Esta é minha!"
             LogMsg('PRODUÇÃO: Produto chegou à entrada! ID lido: ' + IntToStr(ShopResources.AR_In_Part));
             current_operation := Stage_Find_Free_AR;
          end;
        end;

        // --- FASE 7: Encontrar uma posição livre (igual ao Inbound) ---
        Stage_Find_Free_AR:
        begin
          part_position_AR := GET_AR_Position(0, WAREHOUSE_Parts); // Procura um zero (livre)

          if (part_position_AR > 0) then
             current_operation := Stage_Load_AR
          else
             LogMsg('ERRO PRODUÇÃO: Armazém cheio! Não é possível guardar produto final.');
        end;

        // --- FASE 8: Carregar o Produto Final para o Armazém ---
        Stage_Load_AR:
        begin
          if (ShopResources.AR_free) then // Usa a global!
          begin
            r := M_Load(part_position_AR);
            if (r = 1) then
            begin
               ShopResources.AR_free := False; // BLOQUEIA IMEDIATAMENTE O BRAÇO
               Entrada_AR_Reclamada := False;  // Devolve a senha!

               LogMsg('PRODUÇÃO: Concluída! Guardado na pos ' + IntToStr(part_position_AR));
               SET_AR_Position(part_position_AR, part_type, WAREHOUSE_Parts);

               Dec(Em_Processamento); //Atualizar variavel global quando peça entra no armazem deixa de estar a circular

               // ← Incrementar o contador correto
               case part_type of
               Part_Base_Blue:  Inc(Prod_BaseAzul);
               Part_Base_Green: Inc(Prod_BaseVerde);
               Part_Base_Grey:  Inc(Prod_BaseCinza);
               Part_Lid_Blue:   Inc(Prod_TampaAzul);
               Part_Lid_Green:  Inc(Prod_TampaVerde);
               Part_Lid_Grey:   Inc(Prod_TampaCinza);
               end;


               current_operation := Stage_Finished;
            end
            else if (r < 0) then
            begin
               // AVISO: Se por acaso o M_Load falhar (ex: -104 ou -109), ele avisa em vez de congelar em silêncio
               LogMsg('AVISO PRODUÇÃO: A aguardar que M_Load aceite o comando... Erro: ' + IntToStr(r));
            end;
          end;
        end;

        Stage_Finished:
        begin
           // Tarefa de produção concluída
        end;

     end; // fim do case current_operation
  end; // fim do with task
end;


// Procedimento da Expedição - código do professor mas fazia sentido estar aqui
procedure TFormDispatcher.Execute_Expedition_Order(var task:TTask; shopfloor: TResources );
var
    r : integer;
begin
  //  TStage      = (Stage_To_Be_Started = 1, Stage_GetPart, Stage_Unload, Stage_To_AR_Out, Stage_Clear_Pos_AR, Stage_Finished);   //TbC

  with task do
  begin
     case current_operation of

        // To be Started
        Stage_To_Be_Started:
        begin
           // Mantém APENAS a Barreira Verde!
           if (Part_Type <> Part_Base_Green) and (Part_Type <> Part_Lid_Green) then
           begin
             if Tem_Expedicao_Verde_Pendente then
               Exit;
           end;

           current_operation := Stage_GetPart;
        end;

        // Getting a Position from the Warehouse
        Stage_GetPart :
        begin
          if(shopfloor.AR_free) then
          begin
            Part_Position_AR := GET_AR_Position(Part_Type, WAREHOUSE_Parts);
            if( Part_Position_AR > 0 ) then
            begin
               // RESERVA DE SAÍDA (-2)
               SET_AR_Position(Part_Position_AR, -2, WAREHOUSE_Parts);
               current_operation :=  Stage_Unload;
            end
            else
               current_operation :=  Stage_GetPart;
          end;
        end;

        // Request to unload that part
        Stage_Unload :
        begin
          // 2. NOVA REGRA DE BETÃO: A Barreira Física!
          // Se a peça não for verde E houver verdes pendentes, bloqueia o braço!
          if (Part_Type <> Part_Base_Green) and (Part_Type <> Part_Lid_Green) and (Tem_Expedicao_Verde_Pendente) then
            Exit;

          // Se passou a barreira, tenta descarregar:
          if (ShopResources.AR_free) and (ShopResources.AR_Out_Part = 0) then
          begin
            r := M_Unload(Part_Position_AR);
            if ( r = 1 ) then
            begin
               ShopResources.AR_free := False;
               LogMsg('AR Unloading: ' + IntToStr(Part_Position_AR));

               // Peça removida, posição a 0!
               SET_AR_Position(Part_Position_AR, 0, WAREHOUSE_Parts);

               current_operation := Stage_To_AR_Out;
            end;
          end;
        end;

        // Part is in the output conveyor
        Stage_To_AR_Out :
        begin
          if( ShopResources.AR_Out_Part  = Part_Type ) then
          begin
            r := M_Do_Expedition(Part_Destination);          // Expedition

            if( r = 1) then
            begin                                            // <--- FALTAVA ISTO!
               Inc(Total_Expedidas);
               current_operation :=  Stage_Clear_Pos_AR;
            end;                                             // <--- FALTAVA ISTO!
          end;
        end;

        //Updated AR (removing the part from the position)
        Stage_Clear_Pos_AR :
        begin
          // ATENÇÃO: Apaguei o SET_AR_Position daqui!
          current_operation :=  Stage_Finished;
        end;

        //Done.
        Stage_Finished :
        begin
          current_operation :=  Stage_Finished;
        end;
      end;
  end;
end;


// Procedimento que executa uma ordem de Aprovisionamento (Inbound / Delivery)
procedure TFormDispatcher.Execute_Delivery_Order(var task:TTask; shopfloor: TResources );
var
    r : integer; // Variável para guardar a resposta do Autómato (1 para sucesso, < 0 para erro)
begin
  with task do // O "with" facilita o acesso às variáveis da "task" atual (ex: part_type)
  begin
     case current_operation of // Avalia em que fase a máquina de estados está

        // --- FASE 1: Iniciar a Tarefa ---
        Stage_To_Be_Started:

        //Semaforo
        begin
           LogMsg('INBOUND: A iniciar a receção da peça tipo ' + IntToStr(part_type));
           current_operation := Stage_Req_Inbound;
        end;

        // --- FASE 2: Pedir a Matéria-Prima ao Inbound ---
        Stage_Req_Inbound:
        begin
          // Só podemos pedir peças se o equipamento de Inbound não estiver ocupado com outro comando
          if (shopfloor.Inbound_free) then
          begin
            // M_Do_Inbound recebe uma matéria-prima vinda do exterior da fábrica
            r := M_Do_Inbound(part_type);

            // Se o comando foi aceite corretamente (retornou 1)
            if (r = 1) then
            begin
               LogMsg('INBOUND: Comando aceite. A aguardar chegada da peça...');
               // Avança para a fase de espera (o tapete vai rolar até a peça chegar ao armazém)
               current_operation := Stage_Wait_Inbound_Tapete;
            end;
          end;
        end;

        // --- FASE 3: Esperar que a peça chegue ao Tapete de Entrada do Armazém ---
        Stage_Wait_Inbound_Tapete:
        begin
          // NOVA REGRA: A peça é da minha cor E ninguém a reclamou ainda?
          if (shopfloor.AR_In_Part = part_type) and (not Entrada_AR_Reclamada) then
          begin
            Entrada_AR_Reclamada := True; // Tira a senha! "Esta é minha!"
            LogMsg('INBOUND: Peça chegou ao tapete do armazém. A procurar espaço livre...');
            current_operation := Stage_Find_Free_AR;
          end;
        end;

        // --- FASE 4: Encontrar uma posição livre na nossa matriz mental ---
        Stage_Find_Free_AR:
        begin
          part_position_AR := GET_AR_Position(0, WAREHOUSE_Parts);
          if (part_position_AR > 0) then
          begin
             LogMsg('INBOUND: Encontrada posição livre -> ' + IntToStr(part_position_AR));

             // RESERVA DE ENTRADA! O lugar agora é -1 (A Aguardar Preenchimento)
             SET_AR_Position(part_position_AR, -1, WAREHOUSE_Parts);

             current_operation := Stage_Load_AR;
          end
          else
             LogMsg('ERRO INBOUND: Armazém cheio! Não é possível guardar a peça.');
        end;

        // --- FASE 5: Carregar a peça para o Armazém ---
        Stage_Load_AR:
        begin
          if (ShopResources.AR_free) then
          begin
            r := M_Load(part_position_AR);
            if (r = 1) then
            begin
               ShopResources.AR_free := False;
               Entrada_AR_Reclamada := False;
               LogMsg('INBOUND: Peça guardada na posição ' + IntToStr(part_position_AR));

               // Agora sim, substitui a reserva (-1) pela peça verdadeira!
               SET_AR_Position(part_position_AR, part_type, WAREHOUSE_Parts);

               Inc(Total_Recebidas);
               if part_type = Part_Raw_Blue then Inc(Inbound_MP_Azul)
               else if part_type = Part_Raw_Green then Inc(Inbound_MP_Verde)
               else if part_type = Part_Raw_Grey then Inc(Inbound_MP_Cinza);
               current_operation := Stage_Finished;
            end;
          end;
        end;

        // --- FASE 6: Tarefa Terminada ---
        Stage_Finished:
        begin
          // Não precisamos de colocar código aqui.
          // O procedimento "Dispatcher" principal vai ver que o estado é Stage_Finished e passa para a próxima task.
        end;

      end; // Fim do case
  end; // Fim do with
end;


// Função centralizada para escrever no Logger com a hora exata
procedure TFormDispatcher.LogMsg(Texto: string);
begin
  // O formato 'hh:nn:ss' traduz-se para horas:minutos:segundos (ex: [14:30:15])
  memLogger.Append(FormatDateTime('[hh:nn:ss] ', Now) + Texto);
end;

//Descobre se uma matéria-prima que estamos a mandar vir é para usar já nas máquinas, ou se é só para repor o stock final.
function TFormDispatcher.IsReplenishment(const order: TProduction_Order; const allOrders: TArray_Production_Order): Boolean;
var
  i, needed: Integer;
begin
  Result := True;
  for i := 0 to Length(allOrders) - 1 do
  begin
    if allOrders[i].order_type = Type_Production then
    begin
      case allOrders[i].part_type of
        Part_Base_Blue,  Part_Lid_Blue:  needed := Part_Raw_Blue;
        Part_Base_Green, Part_Lid_Green: needed := Part_Raw_Green;
        Part_Base_Grey,  Part_Lid_Grey:  needed := Part_Raw_Grey;
        else                             needed := 0;
      end;
      if needed = order.part_type then
      begin
        Result := False; // Encontrou uma produção que precisa desta MP!
        Exit;
      end;
    end;
  end;
end;


//Dá pontuação 0 aos Cinzentos e Tampas Verdes que já existam, e atira as reposições de stock para o fim com 90 pontos.
function TFormDispatcher.GetOrderPriority(const order: TProduction_Order): Integer;
begin
  // Regra A: Aprovisionamentos só para repor stock vão para o fim da fila
  if (order.order_type = Type_Delivery) and IsReplenishment(order, Production_Orders) then
  begin
    Result := 90;
    Exit;
  end;

  // Regra B: Expedir Verdes que JÁ ESTÃO no armazém é prioridade absoluta!
  if (order.order_type = Type_Expedition) and
     ((order.part_type = Part_Base_Green) or (order.part_type = Part_Lid_Green)) and
     (GET_AR_Position(order.part_type, WAREHOUSE_Parts) > 0) then
  begin
    Result := 0;
    Exit;
  end;

  // Regra C: Pontuações por Cor e Tipo de Tarefa
  case order.part_type of
    // --- CINZENTOS ---
    Part_Raw_Grey, Part_Base_Grey, Part_Lid_Grey:
      case order.order_type of
        Type_Production: Result := -1; // Fura a fila toda.
        Type_Delivery:   Result := 11; // 1º Mandar vir a MP
        Type_Expedition: Result := 22; // 3º Expedir no fim
        else             Result := 99;
      end;

    // --- VERDES ---
    Part_Raw_Green, Part_Base_Green, Part_Lid_Green:
      case order.order_type of
        Type_Delivery:   Result := 10;
        Type_Production: Result := 2;
        Type_Expedition: Result := 21;
        else             Result := 99;
      end;

    // --- AZUIS ---
    Part_Raw_Blue, Part_Base_Blue, Part_Lid_Blue:
      case order.order_type of
        Type_Delivery:   Result := 12;
        Type_Production: Result := 2;
        Type_Expedition: Result := 23;
        else             Result := 99;
      end;

    else Result := 99;
  end;
end;

//O Motor de Ordenação
procedure TFormDispatcher.SmartSortOrders(var orders: TArray_Production_Order);
var
  i, j: Integer;
  key: TProduction_Order;
  keyPriority: Integer;
begin
  for i := 1 to Length(orders) - 1 do
  begin
    key         := orders[i];
    keyPriority := GetOrderPriority(key);
    j := i - 1;
    while (j >= 0) and (GetOrderPriority(orders[j]) > keyPriority) do
    begin
      orders[j + 1] := orders[j];
      Dec(j);
    end;
    orders[j + 1] := key;
  end;
  LogMsg('SISTEMA: Plano reordenado matematicamente com sucesso.');
end;

//Atualiza o Armazem
procedure TFormDispatcher.Atualizar_SCADA_Armazem;
var
  i: integer;
  cMatAzul, cMatVerde, cMatCinza: integer;
  cBaseAzul, cBaseVerde, cBaseCinza: integer;
  cTampaAzul, cTampaVerde, cTampaCinza: integer;
begin
  // 1. Colocar todos os contadores a zero antes de começar a contar
  cMatAzul := 0; cMatVerde := 0; cMatCinza := 0;
  cBaseAzul := 0; cBaseVerde := 0; cBaseCinza := 0;
  cTampaAzul := 0; cTampaVerde := 0; cTampaCinza := 0;

  // 2. Percorrer cada "prateleira" do nosso armazém
  for i := 1 to Length(WAREHOUSE_Parts) - 1 do
  begin
    // Descobrir qual é a peça que está nesta prateleira e somar +1 ao contador certo
    case WAREHOUSE_Parts[i] of
      Part_Raw_Blue:   Inc(cMatAzul);
      Part_Raw_Green:  Inc(cMatVerde);
      Part_Raw_Grey:   Inc(cMatCinza);
      Part_Base_Blue:  Inc(cBaseAzul);
      Part_Base_Green: Inc(cBaseVerde);
      Part_Base_Grey:  Inc(cBaseCinza);
      Part_Lid_Blue:   Inc(cTampaAzul);
      Part_Lid_Green:  Inc(cTampaVerde);
      Part_Lid_Grey:   Inc(cTampaCinza);
    end;
  end;

  // 3. Imprimir o resultado final nas Labels que criaste
  lblArmazemMatAzul.Caption   := 'Matéria Azul: ' + IntToStr(cMatAzul);
  lblArmazemMatVerde.Caption  := 'Matéria Verde: ' + IntToStr(cMatVerde);
  lblArmazemMatCinza.Caption  := 'Matéria Cinza: ' + IntToStr(cMatCinza);

  lblArmazemBaseAzul.Caption  := 'Base Azul: ' + IntToStr(cBaseAzul);
  lblArmazemBaseVerde.Caption := 'Base Verde: ' + IntToStr(cBaseVerde);
  lblArmazemBaseCinza.Caption := 'Base Cinza: ' + IntToStr(cBaseCinza);

  lblArmazemTampaAzul.Caption := 'Tampa Azul: ' + IntToStr(cTampaAzul);
  lblArmazemTampaVerde.Caption:= 'Tampa Verde: ' + IntToStr(cTampaVerde);
  lblArmazemTampaCinza.Caption:= 'Tampa Cinza: ' + IntToStr(cTampaCinza);


  // 4. Atualizar o Fluxo da Fábrica
  lblTotalRecebidas.Caption := 'Matérias Recebidas: ' + IntToStr(Total_Recebidas);
  lblEmProcessamento.Caption := 'Em Processamento: ' + IntToStr(Em_Processamento);
  lblTotalExpedidas.Caption := 'Peças Expedidas: ' + IntToStr(Total_Expedidas);


end;


// ============================================================================
// MÉTRICA 3.5 + 3.6 — UpdateMachineTimers (Lógica Tempo Real + UI Integrada)
// ============================================================================
procedure TFormDispatcher.UpdateMachineTimers(shopfloor: TResources);
var
  Now_T      : TDateTime;
  ElapsedSec : Double;
  espacos_ocupados: integer; // <--- ADICIONAR AQUI
  j: integer;                // <--- ADICIONAR AQUI

  function SecsElapsed(T1, T2: TDateTime): Double;
  begin
    Result := Abs(T2 - T1) * 86400.0; // 1 dia = 86400 segundos
  end;

begin
  Now_T := Now;

  // --------------------------------------------------------------------------
  // 3.5.A — ARMAZÉM AUTOMÁTICO (AR)
  // --------------------------------------------------------------------------
  if not shopfloor.AR_free then
  begin
    if not AR_Was_Busy then
    begin
      AR_Op_Start := Now_T;
      AR_Was_Busy := True;
    end
    else
    begin
      // Se já estava ocupado, soma o 1 segundo que passou e avança a marca temporal
      ElapsedSec := SecsElapsed(AR_Op_Start, Now_T);
      AR_Op_Total := AR_Op_Total + ElapsedSec;
      AR_Op_Start := Now_T;
    end;
  end
  else if AR_Was_Busy then
  begin
    ElapsedSec := SecsElapsed(AR_Op_Start, Now_T);
    AR_Op_Total := AR_Op_Total + ElapsedSec;
    AR_Was_Busy := False;
  end;

  lblTempoAR.Caption := FormatFloat('0.0', AR_Op_Total) + ' s';

  // --------------------------------------------------------------------------
  // 3.5.B — INBOUND
  // --------------------------------------------------------------------------
  if not shopfloor.Inbound_free then
  begin
    if not Inbound_Was_Busy then
    begin
      Inbound_Op_Start := Now_T;
      Inbound_Was_Busy := True;
    end
    else
    begin
      ElapsedSec := SecsElapsed(Inbound_Op_Start, Now_T);
      Inbound_Op_Total := Inbound_Op_Total + ElapsedSec;
      Inbound_Op_Start := Now_T;
    end;
  end
  else if Inbound_Was_Busy then
  begin
    ElapsedSec := SecsElapsed(Inbound_Op_Start, Now_T);
    Inbound_Op_Total := Inbound_Op_Total + ElapsedSec;
    Inbound_Was_Busy := False;
  end;

  lblTempoInbound.Caption := FormatFloat('0.0', Inbound_Op_Total) + ' s';

  // --------------------------------------------------------------------------
  // 3.5.C — CÉLULA 1 (Robot 1)
  // --------------------------------------------------------------------------
  if shopfloor.Robot_1_Part > 0 then
  begin
    if not Cell1_Was_Busy then
    begin
      Cell1_Op_Start := Now_T;
      Cell1_Was_Busy := True;
    end
    else
    begin
      ElapsedSec := SecsElapsed(Cell1_Op_Start, Now_T);
      Cell1_Op_Total := Cell1_Op_Total + ElapsedSec;
      Cell1_Op_Start := Now_T;
    end;
  end
  else if Cell1_Was_Busy then
  begin
    ElapsedSec := SecsElapsed(Cell1_Op_Start, Now_T);
    Cell1_Op_Total := Cell1_Op_Total + ElapsedSec;
    Cell1_Was_Busy := False;
  end;

  lblTempoCell1.Caption := FormatFloat('0.0', Cell1_Op_Total) + ' s';

  // --------------------------------------------------------------------------
  // 3.5.D — CÉLULA 2 (Robot 2)
  // --------------------------------------------------------------------------
  if shopfloor.Robot_2_Part > 0 then
  begin
    if not Cell2_Was_Busy then
    begin
      Cell2_Op_Start := Now_T;
      Cell2_Was_Busy := True;
    end
    else
    begin
      ElapsedSec := SecsElapsed(Cell2_Op_Start, Now_T);
      Cell2_Op_Total := Cell2_Op_Total + ElapsedSec;
      Cell2_Op_Start := Now_T;
    end;
  end
  else if Cell2_Was_Busy then
  begin
    ElapsedSec := SecsElapsed(Cell2_Op_Start, Now_T);
    Cell2_Op_Total := Cell2_Op_Total + ElapsedSec;
    Cell2_Was_Busy := False;
  end;

  lblTempoCell2.Caption := FormatFloat('0.0', Cell2_Op_Total) + ' s';

  // --------------------------------------------------------------------------
  // 3.6 — ESPERA À ENTRADA DO ARMAZÉM (Gargalo)
  // --------------------------------------------------------------------------
  if (shopfloor.AR_In_Part > 0) and (not shopfloor.AR_free) then
  begin
    if not AR_Part_Waiting then
    begin
      AR_Wait_Start   := Now_T;
      AR_Part_Waiting := True;
      Inc(AR_Wait_Count); // Regista que iniciou um novo episódio de espera
    end
    else
    begin
      ElapsedSec      := SecsElapsed(AR_Wait_Start, Now_T);
      AR_Wait_Total   := AR_Wait_Total + ElapsedSec;
      AR_Wait_Start   := Now_T;
    end;
  end
  else if AR_Part_Waiting then
  begin
    ElapsedSec      := SecsElapsed(AR_Wait_Start, Now_T);
    AR_Wait_Total   := AR_Wait_Total + ElapsedSec;
    AR_Part_Waiting := False;
  end;

  // Calculo da média em tempo real
  if AR_Wait_Count > 0 then
     lblTempoEsperaAR.Caption := FormatFloat('0.0', AR_Wait_Total / AR_Wait_Count) + ' s'
  else
     lblTempoEsperaAR.Caption := '0.0 s';

  // ==========================================================================
  // SCADA - DASHBOARD DO ARMAZÉM (KPIs)
  // ==========================================================================

  // 1. A Luz do Braço Mecânico (Verde = Livre, Vermelho = A trabalhar)
  if shopfloor.AR_free then
    FormDispatcher.shpStatusBraco.Brush.Color := clLime
  else
    FormDispatcher.shpStatusBraco.Brush.Color := clRed;

  // 2. O Cronómetro Mestre do Plano
  if Plano_A_Executar then
  begin
    // Calcula os segundos que passaram desde o clique no "Executar"
    Tempo_Total_Plano_Seg := Abs(Now_T - Tempo_Inicio_Plano) * 86400.0;
  end;

  // 3. Imprimir os Tempos
  FormDispatcher.lblScadaTempoPlano.Caption := 'Tempo Total do Plano: ' + FormatFloat('0.0', Tempo_Total_Plano_Seg) + ' s';
  FormDispatcher.lblScadaTempoBraco.Caption := 'Tempo de Trabalho do Braço: ' + FormatFloat('0.0', AR_Op_Total) + ' s';

  // 4. Taxa de Utilização do Braço (Matemática Industrial!)
  if Tempo_Total_Plano_Seg > 0 then
    FormDispatcher.lblScadaUtilizacao.Caption := 'Taxa de Utilização: ' + FormatFloat('0.0', (AR_Op_Total / Tempo_Total_Plano_Seg) * 100) + ' %'
  else
    FormDispatcher.lblScadaUtilizacao.Caption := 'Taxa de Utilização: 0.0 %';

  // 5. A Métrica Bónus: Ocupação do Armazém (%)
  if Length(WAREHOUSE_Parts) > 0 then
  begin
    espacos_ocupados := 0; // Apenas inicia a variável a zero

    for j := 1 to 54 do
    begin
      if WAREHOUSE_Parts[j] > 0 then
        Inc(espacos_ocupados);
    end;

    FormDispatcher.lblScadaLotacao.Caption := 'Ocupação do Armazém: ' + FormatFloat('0.0', (espacos_ocupados / 54.0) * 100) + ' %';
  end;

end;

//PROCEDURE CUSTOS
procedure TFormDispatcher.Atualizar_Custos;
var
  Custo_Materias, Custo_Expedicoes, Custo_Maquinas, Custo_Espera, Custo_Defeitos: Double;
  Custo_Total: Double;
begin
  // 1. Custos das Matérias-Primas (Azul e Cinza = 1€, Verde = 4€)
  Custo_Materias := (Inbound_MP_Azul * 1.0) + (Inbound_MP_Verde * 4.0) + (Inbound_MP_Cinza * 1.0);

  // 2. Custo das Expedições (3€ cada)
  Custo_Expedicoes := Total_Expedidas * 3.0;

  // 3. Custo do Tempo de Máquina (2€ por segundo nas Células 1 e 2)
  Custo_Maquinas := (Cell1_Op_Total + Cell2_Op_Total) * 2.0;

  // 4. Custo da Espera no Armazém (6€ por segundo de tempo médio no gargalo)
  if AR_Wait_Count > 0 then
     begin
          Custo_Espera := (AR_Wait_Total / AR_Wait_Count) * 6.0;
     end
  else
     begin
          Custo_Espera := 0; // Ou outro valor padrão, caso ainda não existam dados
     end;

  // 5. Custo de Defeitos (4€ por peça - valor atualizado via o forms de Defeitos)
  Custo_Defeitos := Total_Defeitos * 4.0;

  // 6. O Somatório Final
  Custo_Total := Custo_Materias + Custo_Expedicoes + Custo_Maquinas + Custo_Espera + Custo_Defeitos;

  // 7. Imprimir no ecrã com as 2 casas decimais habituais dos Euros
  lblCustoTotal.Caption := 'Custo Total: ' + FormatFloat('0.00', Custo_Total) + ' €';
end;

function TFormDispatcher.Contar_Cinzentos_Em_Circulacao: integer;
var
  i, cont: integer;
begin
  cont := 0;
  for i := 0 to Length(ShopTasks) - 1 do
  begin
    //Só contamos se a tarefa for puramente de PRODUÇÃO!
    if ShopTasks[i].task_type = Type_Production then
    begin
      if (ShopTasks[i].part_type = Part_Base_Grey) or
         (ShopTasks[i].part_type = Part_Lid_Grey) then
      begin
        if (ShopTasks[i].current_operation <> Stage_To_Be_Started) and
           (ShopTasks[i].current_operation <> Stage_Finished) then
        begin
          Inc(cont);
        end;
      end;
    end;
  end;
  Result := cont;
end;


function TFormDispatcher.Tem_Expedicao_Verde_Pendente: boolean;
var
  i: integer;
begin
  Result := False;
  for i := 0 to Length(ShopTasks) - 1 do
  begin
    // Se for uma expedição de peça Verde E ainda não estiver terminada...
    if (ShopTasks[i].task_type = Type_Expedition) and
       ((ShopTasks[i].part_type = Part_Base_Green) or (ShopTasks[i].part_type = Part_Lid_Green)) then
    begin
      if ShopTasks[i].current_operation <> Stage_Finished then
      begin
        Result := True; // A barreira desce!
        Exit;
      end;
    end;
  end;
end;

// ==========================================================================
// SCADA MODULAR - ESTADO DA FÁBRICA EM TEMPO REAL
// ==========================================================================
procedure TFormDispatcher.Atualizar_SCADA_Modular;
begin
  // --- ZONA 1: CÉLULA 1 (Máquina das Bases) ---
  if ShopResources.Robot_1_Part > 0 then
  begin
    shpLedCel1.Brush.Color := clRed; // LED Vermelho = A trabalhar
    lblEstadoCel1.Caption := 'Estado: EM OPERAÇÃO';
    lblPecaCel1.Caption := 'Peça Atual: ' + TraduzirPeca(ShopResources.Robot_1_Part);
  end
  else
  begin
    shpLedCel1.Brush.Color := clLime; // LED Verde = Livre
    lblEstadoCel1.Caption := 'Estado: LIVRE';
    lblPecaCel1.Caption := 'Peça Atual: [ Nenhuma ]';
  end;

  // --- ZONA 2: CÉLULA 2 (Máquina das Tampas) ---
  if ShopResources.Robot_2_Part > 0 then
  begin
    shpLedCel2.Brush.Color := clRed;
    lblEstadoCel2.Caption := 'Estado: EM OPERAÇÃO';
    lblPecaCel2.Caption := 'Peça Atual: ' + TraduzirPeca(ShopResources.Robot_2_Part);
  end
  else
  begin
    shpLedCel2.Brush.Color := clLime;
    lblEstadoCel2.Caption := 'Estado: LIVRE';
    lblPecaCel2.Caption := 'Peça Atual: [ Nenhuma ]';
  end;

  // --- ZONA 3: LOGÍSTICA E TAPETES ---
  if ShopResources.Inbound_free then
    lblTapeteInbound.Caption := 'Tapete Inbound: [ Livre ]'
  else
    lblTapeteInbound.Caption := 'Tapete Inbound: OCUPADO (A receber)';

  if ShopResources.AR_In_Part > 0 then
    lblTapeteEntradaAR.Caption := 'Entrada Armazém: ' + TraduzirPeca(ShopResources.AR_In_Part) + ' (A aguardar braço)'
  else
    lblTapeteEntradaAR.Caption := 'Entrada Armazém: [ Livre ]';

  if ShopResources.AR_Out_Part > 0 then
    lblTapeteSaidaAR.Caption := 'Saída Armazém: ' + TraduzirPeca(ShopResources.AR_Out_Part) + ' (Em trânsito)'
  else
    lblTapeteSaidaAR.Caption := 'Saída Armazém: [ Livre ]';
end;

//----------------------------- Fim código interno -----------------------------

//******************************************************************************
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//******************************************************************************


//------------------------------- CÓDIGO BOTÕES --------------------------------


// Botão PLC Conexão
procedure TFormDispatcher.btnPLCClick(Sender: TObject);
var
  result: integer;
begin
  if btnPLC.Caption = 'CONECTAR PLC' then
  begin
    // Tenta estabelecer a ligação com o autómato
    result := M_connect(); //

    if (result = 1) then // Se a ligação for bem sucedida (valor > 0)
    begin
      btnPLC.Caption := 'DESCONECTAR';
      shpStatusPLC.Brush.Color := clRed; // Muda para Vermelho (Ligado)
      LogMsg('SISTEMA: Conectado ao PLC com sucesso.');

      //Desbloqueia Botões
      btnInicializarArmazem.Enabled := True;
      btnAddAprov.Enabled := True;
      btnAddProd.Enabled := True;
      btnAddExp.Enabled := True;
      btnLimpar.Enabled := True;
      btnExecutar.Enabled := True;

    end
    else
    begin
      ShowMessage('Erro: Não foi possível conectar ao PLC. Verifica o programa do autómato!'); //
    end;
  end
  else
  begin
    // Lógica para desligar
    result := M_Disconnect(); // Encerra a conexão com o autómato

    btnPLC.Caption := 'CONECTAR PLC';
    shpStatusPLC.Brush.Color := clLime; // Muda para Verde (Desligado)
    LogMsg('SISTEMA: Desconectado do PLC.');

    //Bloqueia Botoes
    btnInicializarArmazem.Enabled := False;
    btnAddAprov.Enabled := False;
    btnAddProd.Enabled := False;
    btnAddExp.Enabled := False;
    btnLimpar.Enabled := False;
    btnExecutar.Enabled := False;

    // --- NOVIDADE: Colocar as caixas a zero ao desconectar ---
    spnMatAzul.Value := 0;
    spnMatVerde.Value := 0;
    spnMatCinza.Value := 0;
    spnBaseAzul.Value := 0;
    spnBaseVerde.Value := 0;
    spnBaseCinza.Value := 0;
    spnTampaAzul.Value := 0;
    spnTampaVerde.Value := 0;
    spnTampaCinza.Value := 0;

    LogMsg('SISTEMA: Valores de Stock Inicial repostos a zero.');

  end;
end;


//BOTÃO INICIALIZAR ARMAZEM
procedure TFormDispatcher.btnInicializarArmazemClick(Sender: TObject);
var
  TotalPecas, posIndex, cel, r: integer;
  InitPositions: array[1..6] of integer;

  // Vamos criar um procedimento local dentro deste botão para facilitar a inserção
  procedure InserirPeca(CodigoPeca, Quantidade: integer);
  var
    j: integer;
  begin
    for j := 1 to Quantidade do
    begin
      // Envia o comando para a posição válida atual
      r := M_Initialize(InitPositions[posIndex], CodigoPeca);
      if r <= 0 then
       LogMsg('AVISO: Falha ao inserir peça na posição ' + IntToStr(InitPositions[posIndex]));

      // Regista na nossa matriz mental
      WAREHOUSE_Parts[InitPositions[posIndex]] := CodigoPeca;

      Inc(posIndex); // Avança para a próxima posição livre na 1ª coluna
      Sleep(1500);   // Dá tempo ao Factory I/O para processar
    end;
  end;

begin
  // 1. Definir as posições obrigatórias da 1ª coluna
  InitPositions[1] := 1;
  InitPositions[2] := 10;
  InitPositions[3] := 19;
  InitPositions[4] := 28;
  InitPositions[5] := 37;
  InitPositions[6] := 46;

  // 2. Calcular o total de peças pedidas na Interface
  TotalPecas := spnMatAzul.Value + spnMatVerde.Value + spnMatCinza.Value +
                spnBaseAzul.Value + spnBaseVerde.Value + spnBaseCinza.Value +
                spnTampaAzul.Value + spnTampaVerde.Value + spnTampaCinza.Value;

  // 3. Verificação de Segurança
  if TotalPecas > 6 then
  begin
    ShowMessage('Erro: Só pode inicializar um máximo de 6 peças (limite da 1ª coluna do armazém). Reduza os valores!');
    Exit; // Cancela a execução imediatamente
  end;

  if TotalPecas = 0 then
  begin
    ShowMessage('Aviso: Nenhuma peça selecionada para inicializar.');
    Exit;
  end;

  // 4. Preparar o Armazém (Limpar matriz anterior)
  SetLength(WAREHOUSE_Parts, 55);
  for cel := 1 to Length(WAREHOUSE_Parts)-1 do
  begin
      WAREHOUSE_Parts[cel] := 0;
  end;

  LogMsg('SISTEMA: A inicializar ' + IntToStr(TotalPecas) + ' peça(s) no armazém...');

  posIndex := 1; // Aponta para o primeiro espaço válido (InitPositions[1] que é a célula 1)

  // 5. Inserir as peças de acordo com os valores da Interface


  {código teoricamente otimizado mas demora mais tempo:
  // 1º Matéria-Prima Cinzenta (Posição 1 - Arranca logo para a máquina!)
  InserirPeca(Part_Raw_Grey, spnMatCinza.Value);

  // 2º Produtos Verdes Prontos (Posição 10/19 - Expedição imediata a seguir!)
  InserirPeca(Part_Lid_Green, spnTampaVerde.Value);
  InserirPeca(Part_Base_Green, spnBaseVerde.Value);

  // 3º Matéria-Prima Verde (Posição seguinte - Para a outra célula)
  InserirPeca(Part_Raw_Green, spnMatVerde.Value);

  // 4º Matéria-Prima Azul e restantes
  InserirPeca(Part_Raw_Blue, spnMatAzul.Value);
  InserirPeca(Part_Base_Blue, spnBaseAzul.Value);
  InserirPeca(Part_Lid_Blue, spnTampaAzul.Value);
  InserirPeca(Part_Base_Grey, spnBaseCinza.Value);
  InserirPeca(Part_Lid_Grey, spnTampaCinza.Value);    }

  // A função InserirPeca vai usar os códigos corretos das peças
  InserirPeca(Part_Raw_Blue, spnMatAzul.Value);     // Código 1
  InserirPeca(Part_Raw_Green, spnMatVerde.Value);   // Código 2
  InserirPeca(Part_Raw_Grey, spnMatCinza.Value);    // Código 3
  InserirPeca(Part_Base_Blue, spnBaseAzul.Value);   // Código 4
  InserirPeca(Part_Base_Green, spnBaseVerde.Value); // Código 5
  InserirPeca(Part_Base_Grey, spnBaseCinza.Value);  // Código 6
  InserirPeca(Part_Lid_Blue, spnTampaAzul.Value);   // Código 7
  InserirPeca(Part_Lid_Green, spnTampaVerde.Value); // Código 8
  InserirPeca(Part_Lid_Grey, spnTampaCinza.Value);  // Código 9

  LogMsg('SISTEMA: Inicialização do armazém concluída!');

  btnInicializarArmazem.Enabled := False;
  LogMsg('SISTEMA: Botão de inicialização bloqueado por segurança.');

end;


// Traduz o ID numérico da peça para um texto compreensível
function TFormDispatcher.TraduzirPeca(codigo: integer): string;
begin
  case codigo of
    0: Result := '[ Vazio ]';
   -1: Result := '>> A ENTRAR'; // Reserva de Inbound
   -2: Result := '<< A SAIR';   // Reserva de Expedição / Produção
    Part_Raw_Blue:   Result := 'Matéria Azul';
    Part_Raw_Green:  Result := 'Matéria Verde';
    Part_Raw_Grey:   Result := 'Matéria Cinza';
    Part_Base_Blue:  Result := 'Base Azul';
    Part_Base_Green: Result := 'Base Verde';
    Part_Base_Grey:  Result := 'Base Cinza';
    Part_Lid_Blue:   Result := 'Tampa Azul';
    Part_Lid_Green:  Result := 'Tampa Verde';
    Part_Lid_Grey:   Result := 'Tampa Cinza';
    else Result := '???';
  end;
end;

// Layout REAL do Armazém: 9 Colunas x 6 Linhas = 54 posições
procedure TFormDispatcher.Atualizar_Matriz_Armazem;
begin
  // O "Repaint" obriga o Lazarus a redesenhar a grelha NAQUELE EXATO MILISSEGUNDO,
  // chamando o nosso evento de cores (OnDrawCell).
  sgArmazem.Repaint;
end;


//---------------- BOTÕES ADICIONAR ---------------------


//Botão Adicionar Inbound
procedure TFormDispatcher.btnAddAprovClick(Sender: TObject);
begin
  // 1. Verifica se o utilizador escolheu a cor da matéria-prima
  if cbCorAprov.ItemIndex = -1 then
  begin
    ShowMessage('Por favor, selecione a Cor da Matéria-Prima!');
    Exit;
  end;

  // 2. Verifica se a quantidade faz sentido
  if spnQtdAprov.Value <= 0 then
  begin
    ShowMessage('A quantidade tem de ser pelo menos 1!');
    Exit;
  end;

  // 3. O Truque: O código força a palavra "Matéria" automaticamente!
  lstPlano.Items.Add('Aprovisionamento | Matéria ' + cbCorAprov.Text + ' | ' + IntToStr(spnQtdAprov.Value));

  // 4. Regista a ação no nosso Logger
  LogMsg('SISTEMA: Adicionado plano -> Aprovisionamento de ' + IntToStr(spnQtdAprov.Value) + 'x Matéria ' + cbCorAprov.Text);
end;

//Botão Adicionar Produção
procedure TFormDispatcher.btnAddProdClick(Sender: TObject);
begin
  // 1. Verifica se o utilizador escolheu o produto e a cor
  if (cbProdProd.ItemIndex = -1) or (cbCorProd.ItemIndex = -1) then
  begin
    ShowMessage('Por favor, selecione o Produto e a Cor a produzir!');
    Exit;
  end;

  // 2. Verifica se a quantidade faz sentido
  if spnQtdProd.Value <= 0 then
  begin
    ShowMessage('A quantidade tem de ser pelo menos 1!');
    Exit;
  end;

  // 3. Junta tudo e envia para a ListBox no formato padrão
  lstPlano.Items.Add('Produção | ' + cbProdProd.Text + ' ' + cbCorProd.Text + ' | ' + IntToStr(spnQtdProd.Value));

  // 4. Regista a ação no nosso Logger
  LogMsg('SISTEMA: Adicionado plano -> Produção de ' + IntToStr(spnQtdProd.Value) + 'x ' + cbProdProd.Text + ' ' + cbCorProd.Text);
end;

//Botão Adicionar Expedição
procedure TFormDispatcher.btnAddExpClick(Sender: TObject);
begin
  // 1. Verifica se o utilizador escolheu o produto e a cor
  if (cbProdExp.ItemIndex = -1) or (cbCorExp.ItemIndex = -1) then
  begin
    ShowMessage('Por favor, selecione o Produto e a Cor a expedir!');
    Exit;
  end;

  // 2. Verifica se a quantidade é válida
  if spnQtdExp.Value <= 0 then
  begin
    ShowMessage('A quantidade tem de ser pelo menos 1!');
    Exit;
  end;

  // 3. Junta tudo e envia para a ListBox no formato padrão
  lstPlano.Items.Add('Expedição | ' + cbProdExp.Text + ' ' + cbCorExp.Text + ' | ' + IntToStr(spnQtdExp.Value));

  // 4. Regista a ação no nosso Logger
  LogMsg('SISTEMA: Adicionado plano -> Expedição de ' + IntToStr(spnQtdExp.Value) + 'x ' + cbProdExp.Text + ' ' + cbCorExp.Text);
end;

// -----------------------------------------------------------------------------


//Botão Limpar
procedure TFormDispatcher.btnLimparClick(Sender: TObject);
var
  IndexSelecionado: integer;
begin
  // 1. Descobrir qual é a linha que o utilizador selecionou na ListBox
  IndexSelecionado := lstPlano.ItemIndex;

  // 2. Verificar se há realmente algo selecionado (-1 significa que não há nada clicado)
  if IndexSelecionado = -1 then
  begin
    // Nuance: Se a lista estiver totalmente vazia, damos um aviso diferente
    if lstPlano.Items.Count = 0 then
      ShowMessage('O plano já está vazio. Não há registos para limpar!')
    else
      ShowMessage('Atenção: Por favor, clique no registo que deseja apagar antes de carregar em Limpar.');

    Exit; // Sai do procedimento para não tentar apagar o vazio (o que daria erro fatal no programa)
  end;

  // 3. Nuance: Registar no log da fábrica o que estamos a remover antes de o apagar de vez
  LogMsg('SISTEMA: Registo removido do plano -> ' + lstPlano.Items[IndexSelecionado]);

  // 4. Apagar efetivamente a linha selecionada da ListBox
  lstPlano.Items.Delete(IndexSelecionado);
end;


//Botão Executar
procedure TFormDispatcher.btnExecutarClick(Sender: TObject);
var
  i: integer;
  linha, tarefaStr, pecaStr, qtdStr: string;
  pos1, pos2: integer;
  ordem: TProduction_Order;
begin
  // --- FASE 1: Verificações de Segurança ---
  if lstPlano.Items.Count = 0 then
  begin
    ShowMessage('Aviso: O plano está vazio! Adicione tarefas primeiro.');
    Exit;
  end;

  // Garante que o Autómato está ligado antes de enviarmos comandos
  if M_Connection_Status() <= 0 then
  begin
    ShowMessage('Erro Crítico: O PLC não está conectado! Clique em "CONECTAR PLC" primeiro.');
    Exit;
  end;

  // --- FASE 2: Preparar o Array Principal ---
  SetLength(Production_Orders, lstPlano.Items.Count);

  // --- FASE 3: Ler e Traduzir Linha a Linha ---
  for i := 0 to lstPlano.Items.Count - 1 do
  begin
    linha := lstPlano.Items[i]; // Exemplo que estamos a ler: "Produção | Tampa Verde | 2"

    // Cortar a string para extrair a Tarefa
    pos1 := Pos(' | ', linha);
    tarefaStr := Copy(linha, 1, pos1 - 1);
    linha := Copy(linha, pos1 + 3, Length(linha)); // O que sobra: "Tampa Verde | 2"

    // Cortar a string para extrair a Peça e a Quantidade
    pos2 := Pos(' | ', linha);
    pecaStr := Copy(linha, 1, pos2 - 1);
    qtdStr := Copy(linha, pos2 + 3, Length(linha));

    // --- TRADUÇÃO DAS TAREFAS ---
    if tarefaStr = 'Aprovisionamento' then ordem.order_type := Type_Delivery
    else if tarefaStr = 'Produção' then ordem.order_type := Type_Production
    else if tarefaStr = 'Expedição' then ordem.order_type := Type_Expedition;

    // --- TRADUÇÃO DAS PEÇAS ---
    if pecaStr = 'Matéria Azul' then ordem.part_type := Part_Raw_Blue
    else if pecaStr = 'Matéria Verde' then ordem.part_type := Part_Raw_Green
    else if pecaStr = 'Matéria Cinza' then ordem.part_type := Part_Raw_Grey
    else if pecaStr = 'Base Azul' then ordem.part_type := Part_Base_Blue
    else if pecaStr = 'Base Verde' then ordem.part_type := Part_Base_Green
    else if pecaStr = 'Base Cinza' then ordem.part_type := Part_Base_Grey
    else if pecaStr = 'Tampa Azul' then ordem.part_type := Part_Lid_Blue
    else if pecaStr = 'Tampa Verde' then ordem.part_type := Part_Lid_Green
    else if pecaStr = 'Tampa Cinza' then ordem.part_type := Part_Lid_Grey;

    // --- TRADUÇÃO DA QUANTIDADE ---
    ordem.part_numbers := StrToInt(qtdStr);

    // Guardar esta ordem devidamente traduzida no nosso array global
    Production_Orders[i] := ordem;
  end;

  // --- FASE 4: Iniciar o Processo Fabril ---
  LogMsg('SISTEMA: A converter ' + IntToStr(lstPlano.Items.Count) + ' linha(s) para tarefas de máquina...');



  //Otimizar a Ordem
  SmartSortOrders(Production_Orders);


  // Reiniciamos o índice de execução (crucial se fores executar vários planos seguidos)
  idx_Task_Executing := 0;

  // Usamos a função do professor para transformar estas ordens nas "Stages" da máquina de estados
  SimpleScheduler(Production_Orders, ShopTasks);

  // Ligar o "motor" (se não estivesse já ligado)
  Timer1.Enabled := true;

  // Iniciar o cronómetro mestre - KPIs
  Plano_A_Executar := True;
  Tempo_Inicio_Plano := Now;
  Tempo_Total_Plano_Seg := 0;

  LogMsg('SISTEMA: Execução do plano iniciada!');
end;


//BOTÃO Extrair Relatório
procedure TFormDispatcher.btnExtrairRelatorioClick(Sender: TObject);
var
  NomeFicheiro: string;
begin
  // 1. Verificar se há realmente algo para guardar
  if memLogger.Lines.Count = 0 then
  begin
    ShowMessage('Aviso: O Logger está vazio. Não há nada para extrair!');
    Exit;
  end;

  // 2. Criar um nome de ficheiro único com a data e hora atual
  // Exemplo de como vai ficar: "Relatorio_HS_Systems_20260326_184530.txt"
  NomeFicheiro := 'Relatorio_HS_Systems_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.txt';

  try
    // 3. Guardar tudo num ficheiro com 1 linha de código!
    memLogger.Lines.SaveToFile(NomeFicheiro);

    // 4. Avisar o utilizador (no próprio log e com um pop-up)
    LogMsg('SISTEMA: Relatório extraído com sucesso para o ficheiro -> ' + NomeFicheiro);
    ShowMessage('Sucesso! Relatório guardado na pasta do teu projeto como: ' + sLineBreak + NomeFicheiro);
  except
    // Caso o Windows bloqueie a gravação por falta de permissões
    ShowMessage('Erro: Não foi possível guardar o ficheiro. Verifique as permissões da pasta.');
  end;
end;


//******************************************************************************
//Botões na Tab de Monitorização
//******************************************************************************

//Botão Limpar
procedure TFormDispatcher.btnDefeitosLimparClick(Sender: TObject);
var
  IndexSelecionado: integer;
begin
  // 1. Descobrir qual é a linha que o utilizador selecionou na ListBox
  IndexSelecionado := lstDefeito.ItemIndex;

  // 2. Verificar se há realmente algo selecionado (-1 significa que não há nada clicado)
  if IndexSelecionado = -1 then
  begin
    // Nuance: Se a lista estiver totalmente vazia, damos um aviso diferente
    if lstPlano.Items.Count = 0 then
      ShowMessage('O plano já está vazio. Não há registos para limpar!')
    else
      ShowMessage('Atenção: Por favor, clique no registo que deseja apagar antes de carregar em Limpar.');

    Exit; // Sai do procedimento para não tentar apagar o vazio (o que daria erro fatal no programa)
  end;

  // 3. Nuance: Registar no log da fábrica o que estamos a remover antes de o apagar de vez
  LogMsg('SISTEMA: Registo removido do plano -> ' + lstPlano.Items[IndexSelecionado]);

  // 4. Apagar efetivamente a linha selecionada da ListBox
  lstDefeito.Items.Delete(IndexSelecionado);
end;

//Botão Adicionar Defeito
procedure TFormDispatcher.btnAdicionarDefeitoClick(Sender: TObject);
begin
  // 1. Verifica se o utilizador escolheu o produto e a cor
  if (cbTipoDefeito.ItemIndex = -1) or (cbCorDefeito.ItemIndex = -1) then
  begin
    ShowMessage('Por favor, selecione o Tipo e a Cor a produzir!');
    Exit;
  end;

  // 2. Verifica se a quantidade faz sentido
  if StrToIntDef(spnQuantidadeDefeito.Text,0) <= 0 then
  begin
    ShowMessage('A quantidade tem de ser pelo menos 1!');
    Exit;
  end;

  // 3. Junta tudo e envia para a ListBox no formato padrão
  lstDefeito.Items.Add('Produção | ' + cbTipoDefeito.Text + ' ' + cbCorDefeito.Text + ' | ' + spnQuantidadeDefeito.Text);

  // 4. Regista a ação no nosso Logger
  LogMsg('SISTEMA: Adicionado defeito -> Defeito em ' + IntToStr(spnQuantidadeDefeito.Value) + 'x ' + cbTipoDefeito.Text + ' ' + cbCorDefeito.Text);
end;


procedure TFormDispatcher.btnDefeitoConfirmarClick(Sender: TObject);
var
  // Contadores de peças produzidas (concluídas com sucesso)
  cBaseAzul, cBaseVerde, cBaseCinza: integer;
  cTampaAzul, cTampaVerde, cTampaCinza: integer;
  // Contadores de defeituosos
  dBaseAzul, dBaseVerde, dBaseCinza: integer;
  dTampaAzul, dTampaVerde, dTampaCinza: integer;
  i: integer;
  linha, pecaStr, qtdStr: string;
  pos1: integer;
  qtd: integer;
begin
  // --- FASE 1: Contar peças produzidas a partir das tarefas concluídas ---
  cBaseAzul  := Prod_BaseAzul;
  cBaseVerde := Prod_BaseVerde;
  cBaseCinza := Prod_BaseCinza;
  cTampaAzul := Prod_TampaAzul;
  cTampaVerde:= Prod_TampaVerde;
  cTampaCinza:= Prod_TampaCinza;

  // --- FASE 2: Contar defeituosos a partir da lstDefeito ---
  // Formato esperado de cada linha: "Produção | Tampa Verde | 2"
  dBaseAzul  := 0; dBaseVerde  := 0; dBaseCinza  := 0;
  dTampaAzul := 0; dTampaVerde := 0; dTampaCinza := 0;

  for i := 0 to lstDefeito.Items.Count - 1 do
  begin
    linha := lstDefeito.Items[i];

    // Extrai a parte depois do primeiro " | "
    pos1 := Pos(' | ', linha);
    if pos1 = 0 then Continue;
    linha := Copy(linha, pos1 + 3, Length(linha));

    // Extrai o nome da peça e a quantidade
    pos1 := Pos(' | ', linha);
    if pos1 = 0 then Continue;
    pecaStr := Copy(linha, 1, pos1 - 1);
    qtdStr  := Copy(linha, pos1 + 3, Length(linha));

    qtd := StrToIntDef(qtdStr, 0);

    if pecaStr = 'Base Azul'   then Inc(dBaseAzul,  qtd)
    else if pecaStr = 'Base Verde'  then Inc(dBaseVerde, qtd)
    else if pecaStr = 'Base Cinza'  then Inc(dBaseCinza, qtd)
    else if pecaStr = 'Tampa Azul'  then Inc(dTampaAzul, qtd)
    else if pecaStr = 'Tampa Verde' then Inc(dTampaVerde, qtd)
    else if pecaStr = 'Tampa Cinza' then Inc(dTampaCinza, qtd);
  end;

  // --- FASE 3: Preencher o StringGrid (Total | OK = Total - Defeitos | Defeituoso) ---
  // Base Azul (linha 1)
  StringGrid1.Cells[1, 1] := IntToStr(cBaseAzul);
  StringGrid1.Cells[3, 1] := IntToStr(dBaseAzul);
  StringGrid1.Cells[2, 1] := IntToStr(cBaseAzul - dBaseAzul);

  // Base Verde (linha 2)
  StringGrid1.Cells[1, 2] := IntToStr(cBaseVerde);
  StringGrid1.Cells[3, 2] := IntToStr(dBaseVerde);
  StringGrid1.Cells[2, 2] := IntToStr(cBaseVerde - dBaseVerde);

  // Base Cinza (linha 3)
  StringGrid1.Cells[1, 3] := IntToStr(cBaseCinza);
  StringGrid1.Cells[3, 3] := IntToStr(dBaseCinza);
  StringGrid1.Cells[2, 3] := IntToStr(cBaseCinza - dBaseCinza);

  // Tampa Azul (linha 4)
  StringGrid1.Cells[1, 4] := IntToStr(cTampaAzul);
  StringGrid1.Cells[3, 4] := IntToStr(dTampaAzul);
  StringGrid1.Cells[2, 4] := IntToStr(cTampaAzul - dTampaAzul);

  // Tampa Verde (linha 5)
  StringGrid1.Cells[1, 5] := IntToStr(cTampaVerde);
  StringGrid1.Cells[3, 5] := IntToStr(dTampaVerde);
  StringGrid1.Cells[2, 5] := IntToStr(cTampaVerde - dTampaVerde);

  // Tampa Cinza (linha 6)
  StringGrid1.Cells[1, 6] := IntToStr(cTampaCinza);
  StringGrid1.Cells[3, 6] := IntToStr(dTampaCinza);
  StringGrid1.Cells[2, 6] := IntToStr(cTampaCinza - dTampaCinza);

  // --- FASE 4: Ligar à Monitorização de Custos ---
  Total_Defeitos := dBaseAzul + dBaseVerde + dBaseCinza + dTampaAzul + dTampaVerde + dTampaCinza;

  LogMsg('QUALIDADE: Tabela de análise atualizada com ' + IntToStr(lstDefeito.Items.Count) + ' registo(s) de defeito.');
end;


//----------------------------- Fim código Botões -----------------------------


//******************************************************************************
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//******************************************************************************

end.

