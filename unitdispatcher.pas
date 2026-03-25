unit unitdispatcher;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
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
    Memo1: TMemo;
    Timer1: TTimer;
    procedure BExecuteClick(Sender: TObject);
    procedure BInitiatilizeClick(Sender: TObject);
    procedure BStartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private

  public
    procedure Dispatcher(var tasks:TArray_Task; var idx : integer; shopfloor: TResources );
    procedure Execute_Expedition_Order(var task:TTask; shopfloor: TResources );

    procedure Execute_Delivery_Order(var task:TTask; shopfloor: TResources ); //inbound dispacher

    procedure Execute_Production_Order(var task:TTask; shopfloor: TResources ); //Production

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




// Query DB -> Scheduling -> Connect PLC for Dispatching
procedure TFormDispatcher.BStartClick(Sender: TObject);
var
    result           : integer;
    production_order : TProduction_Order;
begin
  // ******************************************
  // Query to DB and converts data to structures
  // ...      to be completed by the STUDENT after SQL introduction in INFI.
  // *******************************************



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

procedure TFormDispatcher.FormCreate(Sender: TObject);
begin
  SetLength(ShopTasks, 0);
  idx_Task_Executing := 0;
end;

procedure TFormDispatcher.Timer1Timer(Sender: TObject);
begin
  BExecuteClick(Self);
end;




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
    Memo1.Append('Innitiatialization with errors');

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
  SimpleScheduler(Production_Orders, ShopTasks);


  // Starting Dispatcher Iterations over time
  Timer1.Enabled:= true;
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



// Global Dispatcher - SIMPLEX
procedure TFormDispatcher.Dispatcher(var tasks:TArray_Task; var idx : integer; shopfloor: TResources );
begin
    case tasks[idx].task_type of

      // Expedition
      Type_Expedition :
      begin
        if(idx < Length(tasks)) then
        begin
          Memo1.Append('Task Expedition');
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
          Memo1.Append('Task Production');

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
          Memo1.Append('Task Inbound/Delivery');

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


// Procedure that executes an expedition order according to SLIDE 19 of T classes.
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
            Memo1.Append(IntToStr(Part_Position_AR));

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
          Memo1.Append('AR Unloading: ' + IntToStr(Part_Position_AR));
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
           Memo1.Append('INBOUND: A iniciar a receção da peça tipo ' + IntToStr(part_type));
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
               Memo1.Append('INBOUND: Comando aceite. A aguardar chegada da peça...');
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
            Memo1.Append('INBOUND: Peça chegou ao tapete do armazém. A procurar espaço livre...');
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
             Memo1.Append('INBOUND: Encontrada posição livre -> ' + IntToStr(part_position_AR));
             // Já temos um alvo. Vamos dar ordem ao braço do armazém para ir buscar a peça.
             current_operation := Stage_Load_AR;
          end
          else
          begin
             // Se part_position_AR for 0, o armazém está totalmente cheio.
             Memo1.Append('ERRO INBOUND: Armazém cheio! Não é possível guardar a peça.');
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
               Memo1.Append('INBOUND: Peça guardada na posição ' + IntToStr(part_position_AR));
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
           Memo1.Append('PRODUÇÃO: Iniciar peça ' + IntToStr(part_type) + '. A procurar MP ' + IntToStr(raw_material_needed));
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
               Memo1.Append('PRODUÇÃO: MP encontrada na posição ' + IntToStr(part_position_AR));
               current_operation :=  Stage_Unload;
            end
            else
            begin
               // Fica aqui "preso" até que a matéria-prima dê entrada no armazém
               Memo1.Append('AVISO PRODUÇÃO: A aguardar MP ' + IntToStr(raw_material_needed) + ' no armazém...');
            end;
          end;
        end;

        // --- FASE 3: Descarregar a MP ---
        Stage_Unload :
        begin
          r := M_Unload(part_position_AR); // Pede para tirar a peça

          if ( r = 1 ) then
          begin
             Memo1.Append('PRODUÇÃO: A descarregar MP...');
             current_operation := Stage_Wait_AR_Out_Prod;
          end;
        end;

        // --- FASE 4: Esperar que a MP chegue ao tapete de saída ---
        Stage_Wait_AR_Out_Prod :
        begin
          // A peça tem de estar no tapete de saída antes de enviarmos para a máquina
          if( ShopResources.AR_Out_Part = raw_material_needed ) then
          begin
             Memo1.Append('PRODUÇÃO: MP no tapete de saída. A enviar para célula ' + IntToStr(part_destination));
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
             Memo1.Append('PRODUÇÃO: A processar na máquina. A aguardar regresso...');
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
             Memo1.Append('PRODUÇÃO: Produto chegou à entrada! ID lido: ' + IntToStr(ShopResources.AR_In_Part));
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
             Memo1.Append('ERRO PRODUÇÃO: Armazém cheio! Não é possível guardar produto final.');
        end;

        // --- FASE 8: Carregar o Produto Final para o Armazém ---
        Stage_Load_AR:
        begin
          if (shopfloor.AR_free) then
          begin
            r := M_Load(part_position_AR);

            if (r = 1) then
            begin
               Memo1.Append('PRODUÇÃO: Concluída! Guardado na pos ' + IntToStr(part_position_AR));
               SET_AR_Position(part_position_AR, part_type, WAREHOUSE_Parts);
               current_operation := Stage_Finished;
            end
            else if (r < 0) then
            begin
               // AVISO: Se por acaso o M_Load falhar (ex: -104 ou -109), ele avisa em vez de congelar em silêncio
               Memo1.Append('AVISO PRODUÇÃO: A aguardar que M_Load aceite o comando... Erro: ' + IntToStr(r));
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



end.

