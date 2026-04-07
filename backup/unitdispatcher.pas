unit unitdispatcher;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Menus, ComCtrls, Buttons, Spin, Grids,
  comUnit;

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
    cbCorProd: TComboBox;
    cbCorExp: TComboBox;
    cbProduto: TComboBox;
    cbCorAprov: TComboBox;
    cbProdProd: TComboBox;
    cbProdExp: TComboBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
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
    labelRelogio: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lstPlano: TListBox;
    memLogger: TMemo;
    PageControl1: TPageControl;
    Header: TPanel;
    Footer: TPanel;
    PageControlTarefas: TPageControl;
    panelProducao: TPanel;
    panelArmazem: TPanel;
    pnlRelogio: TPanel;
    btnPLC: TSpeedButton;
    Shape1: TShape;
    shpStatusPLC: TShape;
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
    StringGrid1: TStringGrid;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheet5: TTabSheet;
    TabSheet6: TTabSheet;
    TabSheet7: TTabSheet;
    Expedicao: TTabSheet;
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
    procedure Timer1Timer(Sender: TObject);
  private

  public
    procedure Dispatcher(var tasks:TArray_Task; var idx : integer; shopfloor: TResources );
    procedure Execute_Expedition_Order(var task:TTask; shopfloor: TResources );

    procedure Execute_Delivery_Order(var task:TTask; shopfloor: TResources ); //inbound dispacher

    procedure Execute_Production_Order(var task:TTask; shopfloor: TResources ); //Production

    procedure LogMsg(Texto: string); //Logger para aparecer as horas

    procedure Priorizar_Expedicao_Verdes; // Lógica verdes primeiro

    function GET_AR_Position (Part : integer; Warehouse : array of integer): integer;
    procedure SET_AR_Position (idx : integer; Part : integer; var Warehouse : array of integer);

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
    resp : array[1..8] of integer;
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
  resp:=M_Get_Factory_Status();

  with shopfloor do
  begin
    Inbound_free := Int(resp[2]) = 1;
    AR_free      := Int(resp[3]) = 1;
    AR_In_Part   := LongInt(resp[4]);
    AR_Out_Part  := LongInt(resp[5]);
    Robot_1_Part := LongInt(resp[6]);
    Robot_2_Part := LongInt(resp[7]);
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
end;


procedure TFormDispatcher.Timer1Timer(Sender: TObject);
begin
  BExecuteClick(Self);
  labelRelogio.Caption := FormatDateTime('hh:nn:ss', Now);
end;


// get the first position (cell) in AR that contains the "Part"
function TFormDispatcher.GET_AR_Position (Part : integer; Warehouse : array of integer): integer;
var
    i : integer;
begin
  for i := 1 to Length(Warehouse)-1 do   //bug alterado de 0 para 1!
  begin
      if Warehouse[i] = Part then
      begin
          result := i;
          Exit;
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
    Dispatcher(ShopTasks, idx_Task_Executing, ShopResources);
  end;
end;


//-------------------- FIM PROCEDURES PRÉ-FEITAS PROFESSOR ---------------------


//******************************************************************************
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//******************************************************************************


//---------------------- CÓDIGO INTERNO - ALTERADO/FEITO -----------------------


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
        begin
           LogMsg('PRODUÇÃO: Iniciar peça ' + IntToStr(part_type) + '. A procurar MP ' + IntToStr(raw_material_needed));
           current_operation :=  Stage_GetPart;
        end;

        // --- FASE 2: Procurar a MP no armazém ---
        Stage_GetPart :
        begin
          if(shopfloor.AR_free) then  // Se o armazém estiver livre
          begin
            // Procura a posição da matéria-prima que definimos lá em cima
            part_position_AR := GET_AR_Position(raw_material_needed, WAREHOUSE_Parts);

            if( part_position_AR > 0 ) then
            begin
               LogMsg('PRODUÇÃO: MP encontrada na posição ' + IntToStr(part_position_AR));
               current_operation :=  Stage_Unload;
            end
            else
            begin
               // Fica aqui "preso" até que a matéria-prima dê entrada no armazém
               LogMsg('AVISO PRODUÇÃO: A aguardar MP ' + IntToStr(raw_material_needed) + ' no armazém...');
            end;
          end;
        end;

        // --- FASE 3: Descarregar a MP ---
        Stage_Unload :
        begin
          r := M_Unload(part_position_AR); // Pede para tirar a peça

          if ( r = 1 ) then
          begin
             LogMsg('PRODUÇÃO: A descarregar MP...');
             current_operation := Stage_Wait_AR_Out_Prod;
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
          // O "part_destination" (1 para Bases, 2 para Tampas) já foi preenchido pelo SimpleScheduler do professor
          r := M_Do_Production(part_destination);

          if (r = 1) then
          begin
             LogMsg('PRODUÇÃO: A processar na máquina. A aguardar regresso...');
             // A peça já não está no armazém, podemos libertar o "nosso" registo virtual
             SET_AR_Position(part_position_AR, 0, WAREHOUSE_Parts);
             current_operation := Stage_Wait_Prod_Return;
          end;
        end;

        // --- FASE 6: Esperar que o Produto Final regresse à entrada ---
        Stage_Wait_Prod_Return:
        begin
          // Alterado para '> 0'. Se há uma peça no tapete, é a nossa!
          if (ShopResources.AR_In_Part > 0) then
          begin
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
          if (shopfloor.AR_free) then
          begin
            r := M_Load(part_position_AR);

            if (r = 1) then
            begin
               LogMsg('PRODUÇÃO: Concluída! Guardado na pos ' + IntToStr(part_position_AR));
               SET_AR_Position(part_position_AR, part_type, WAREHOUSE_Parts);
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
           current_operation :=  Stage_GetPart;
        end;

        // Getting a Position from the Warehouse
        Stage_GetPart :
        begin
          if(shopfloor.AR_free) then  //AR is free
          begin
            Part_Position_AR := GET_AR_Position(Part_Type, WAREHOUSE_Parts);
            LogMsg(IntToStr(Part_Position_AR));

            if( Part_Position_AR > 0 ) then
            begin
               current_operation :=  Stage_Unload;
            end
            else
            begin
               current_operation :=  Stage_GetPart;
            end;
          end;
        end;

        // Request to unload that part
        Stage_Unload :
        begin
          LogMsg('AR Unloading: ' + IntToStr(Part_Position_AR));
          r := M_Unload(Part_Position_AR);

          if ( r = 1 ) then                                 //sucess
             current_operation :=  Stage_To_AR_Out;
        end;

        // Part is in the output conveyor
        Stage_To_AR_Out :
        begin
          if( ShopResources.AR_Out_Part  = Part_Type ) then
          begin
            r := M_Do_Expedition(Part_Destination);          // Expedition

            if( r = 1) then                                  // sucess
             current_operation :=  Stage_Clear_Pos_AR;
          end;
        end;

        //Updated AR (removing the part from the position)
        Stage_Clear_Pos_AR :
        begin
          SET_AR_Position(Part_Position_AR, 0, WAREHOUSE_Parts);
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
        begin
           LogMsg('INBOUND: A iniciar a receção da peça tipo ' + IntToStr(part_type));
           // Passa imediatamente para a próxima fase, onde vamos enviar o comando ao Factory IO
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
          // A matéria-prima depois de recebida é encaminhada automaticamente para o tapete de entrada do armazém.
          // Aqui verificamos ciclicamente se o sensor do tapete de entrada já detetou a nossa peça.
          if (shopfloor.AR_In_Part = part_type) then
          begin
            LogMsg('INBOUND: Peça chegou ao tapete do armazém. A procurar espaço livre...');
            // A peça chegou fisicamente! Agora vamos procurar um lugar para a guardar
            current_operation := Stage_Find_Free_AR;
          end;
        end;

        // --- FASE 4: Encontrar uma posição livre na nossa matriz mental ---
        Stage_Find_Free_AR:
        begin
          // Aproveitamos a função do professor "GET_AR_Position".
          // Ao pedir a peça "0", a função vai procurar a primeira célula vazia (com valor 0) no WAREHOUSE_Parts.
          part_position_AR := GET_AR_Position(0, WAREHOUSE_Parts);

          // Como as posições do armazém vão de 1 a 54, se for > 0 significa que encontrou espaço.
          if (part_position_AR > 0) then
          begin
             LogMsg('INBOUND: Encontrada posição livre -> ' + IntToStr(part_position_AR));
             // Já temos um alvo. Vamos dar ordem ao braço do armazém para ir buscar a peça.
             current_operation := Stage_Load_AR;
          end
          else
          begin
             // Se part_position_AR for 0, o armazém está totalmente cheio.
             LogMsg('ERRO INBOUND: Armazém cheio! Não é possível guardar a peça.');
             // Por agora, o código fica bloqueado nesta fase até que se liberte espaço.
          end;
        end;

        // --- FASE 5: Carregar a peça para o Armazém ---
        Stage_Load_AR:
        begin
          // O Armazém só executa 1 comando de cada vez. Temos de garantir que está livre.
          if (shopfloor.AR_free) then
          begin
            // O comando M_Load carrega a peça do tapete de entrada e coloca-a na posição definida.
            r := M_Load(part_position_AR);

            // Se o comando foi executado corretamente (retornou 1)
            if (r = 1) then
            begin
               LogMsg('INBOUND: Peça guardada na posição ' + IntToStr(part_position_AR));
               // Guardamos a informação de que a posição deixou de estar livre e tem a nova peça
               SET_AR_Position(part_position_AR, part_type, WAREHOUSE_Parts);
               // A ordem de Aprovisionamento está oficialmente concluída!
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

//Procedimento priorizar verdes
procedure TFormDispatcher.Priorizar_Expedicao_Verdes;
var
  i, indexVerdes, indexOutros: integer;
  ListaVerdes, ListaOutros: array of TProduction_Order;
  ordem: TProduction_Order;
begin
  indexVerdes := 0;
  indexOutros := 0;

  // 1. Percorrer o plano original e separar
  for i := 0 to Length(Production_Orders) - 1 do
  begin
    ordem := Production_Orders[i];

    // NOVA LÓGICA: Se for uma peça da família VERDE (Matéria, Base ou Tampa)
    // Puxamos todas as tarefas associadas a elas para o topo!
    if (ordem.part_type = Part_Base_Green) or
       (ordem.part_type = Part_Lid_Green) or
       (ordem.part_type = Part_Raw_Green) then
    begin
      SetLength(ListaVerdes, indexVerdes + 1);
      ListaVerdes[indexVerdes] := ordem;
      Inc(indexVerdes); // Como o ciclo for avança de cima para baixo, a Produção entra sempre antes da Expedição!
    end
    else
    begin
      // Peças Azuis e Cinzentas ficam na lista de espera
      SetLength(ListaOutros, indexOutros + 1);
      ListaOutros[indexOutros] := ordem;
      Inc(indexOutros);
    end;
  end;

  // 2. Reconstruir o array principal: Primeiro todos os passos dos Verdes!
  for i := 0 to indexVerdes - 1 do
  begin
    Production_Orders[i] := ListaVerdes[i];
  end;

  // 3. Reconstruir o array principal: Depois as restantes peças
  for i := 0 to indexOutros - 1 do
  begin
    Production_Orders[indexVerdes + i] := ListaOutros[i];
  end;

  // 4. Se encontrou alguma peça verde para puxar para cima, avisa no Logger
  if indexVerdes > 0 then
    LogMsg('SISTEMA: Regra aplicada! ' + IntToStr(indexVerdes) + ' tarefa(s) da família Verde puxadas para o início da fila.');
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

  //Priorizar a expedição das peças verdes
  Priorizar_Expedicao_Verdes;

  // Reiniciamos o índice de execução (crucial se fores executar vários planos seguidos)
  idx_Task_Executing := 0;

  // Usamos a função do professor para transformar estas ordens nas "Stages" da máquina de estados
  SimpleScheduler(Production_Orders, ShopTasks);

  // Ligar o "motor" (se não estivesse já ligado)
  Timer1.Enabled := true;

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


//----------------------------- Fim código Botões -----------------------------


//******************************************************************************
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//******************************************************************************

end.

