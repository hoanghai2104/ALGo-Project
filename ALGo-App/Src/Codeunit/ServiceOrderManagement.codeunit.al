codeunit 50103 ServiceOrderManagement
{
    trigger OnRun()
    begin

    end;


    procedure createServiceOrder(var salesHeader: Record "Sales Header")
    var
        serviceHeader: Record "Service Header";
        serviceMgtSetup: Record "Service Mgt. Setup";
        serviceOrder: Page "Service Order";
    begin

        if (salesHeader."Type commande service" <> 'INSTALLATI') then begin
            salesHeader.FieldError("Type commande service", 'Invalid');
            exit;
        end;
        salesHeader."Statut commande" := salesHeader."Statut commande"::Pending;

        serviceHeader.Reset();
        serviceHeader.SetRange("Document Type", serviceHeader."Document Type"::Order);
        serviceHeader.SetRange("Sales Order Reference", salesHeader."No.");

        if serviceHeader.FindFirst() then begin
            serviceHeader."Customer No." := salesHeader."Sell-to Customer No.";
            serviceHeader."Contact No." := salesHeader."Sell-to Contact No.";
            serviceHeader.Validate("Customer No.");
            // serviceHeader.Validate("Contact No.");
            serviceHeader.Status := salesHeader."Statut commande";
            serviceHeader."Service Order Type" := salesHeader."Type commande service";
            serviceHeader."Nom du Proprietaire" := salesHeader."Nom du Proprietaire";
            serviceHeader.Validate("Nom du Proprietaire");
            // serviceHeader."Ship-to Code" := salesHeader."Ship-to Code";
            // serviceHeader.Validate("Ship-to Code");
            serviceHeader.TechnitianName := salesHeader.TechnitianName;
            serviceheader."Nom du technicien" := salesHeader."Nom du technicien";
            this.shiptoAddress(salesHeader, serviceHeader);

            serviceHeader.Modify(true);

        end else begin
            serviceMgtSetup.Get();
            serviceMgtSetup.TestField("Service Order Nos.");

            serviceHeader.Init();
            serviceHeader."Document Type" := serviceHeader."Document Type"::Order;
            serviceHeader."Customer No." := salesHeader."Sell-to Customer No.";
            serviceHeader."Contact No." := salesHeader."Sell-to Contact No.";
            serviceHeader.Validate("Customer No.");
            // serviceHeader.Validate("Contact No.");
            serviceHeader.Status := salesHeader."Statut commande";
            serviceHeader."Service Order Type" := salesHeader."Type commande service";
            serviceHeader."Sales Order Reference" := salesHeader."No.";
            // serviceHeader."Ship-to Code" := salesHeader."Ship-to Code";
            // serviceHeader.Validate("Ship-to Code");
            serviceHeader."Nom du Proprietaire" := salesHeader."Nom du Proprietaire";
            serviceHeader.Validate("Nom du Proprietaire");
            serviceHeader.TechnitianName := salesHeader.TechnitianName;
            serviceheader."Nom du technicien" := salesHeader."Nom du technicien";

            this.shiptoAddress(salesHeader, serviceHeader);
            serviceHeader.Insert(true);
        end;

        this.createServiceOrderLine(salesHeader, serviceHeader);

        if not this.ConfirmManagement.GetResponseOrDefault('Do you want to open the Service order?', false) then
            exit;
        serviceOrder.SetRecord(serviceHeader);
        serviceOrder.Run();

    end;

    local procedure shiptoAddress(var salesHeader: Record "Sales Header"; var serviceHeader: Record "Service Header")
    var
    begin
        if salesHeader."Ship-to Code" <> '' then begin
            serviceHeader."Ship-to Code" := salesHeader."Ship-to Code";
            serviceHeader.Validate("Ship-to Code");

            exit;
        end;
        serviceHeader."Ship-to Name" := salesHeader."Ship-to Name";
        serviceHeader."Ship-to Address" := salesHeader."Ship-to Address";
        serviceHeader."Ship-to Address 2" := salesHeader."Ship-to Address 2";
        serviceHeader."Ship-to City" := salesHeader."Ship-to City";
        serviceHeader."Ship-to Post Code" := salesHeader."Ship-to Post Code";
        serviceHeader."Ship-to County" := salesHeader."Ship-to County";
        serviceHeader."Ship-to Country/Region Code" := salesHeader."Ship-to Country/Region Code";
        serviceHeader."Ship-to Contact" := salesHeader."Ship-to Contact";
    end;


    procedure createServiceOrderLine(var salesHeader: Record "Sales Header"; var serviceHeader: Record "Service Header")
    var
        salesLine: Record "Sales Line";
        // serviceItemLine: Record "Service Item Line";
        item: Record Item;
        serviceItemLine: Record "Service Item Line";
    begin
        salesLine.Reset();
        salesLine.SetRange("Document Type", salesHeader."Document Type");
        salesLine.SetRange("Document No.", salesHeader."No.");

        if salesLine.FindSet() then
            repeat
                if salesLine.Type <> salesLine.Type::Item then
                    continue;
                item.Get(salesLine."No.");
                if item.Type = item.Type::Inventory then begin
                    this.createServiceItemLine(salesLine, serviceHeader, serviceItemLine);
                end;

                this.createServiceLine(salesLine, serviceHeader, serviceItemLine);

            until salesLine.Next() = 0;
    end;

    procedure createServiceItemLine(var salesLine: Record "Sales Line"; var serviceHeader: record "Service Header"; var serviceItemLine: Record "Service Item Line"): Integer
    var
        serviceItemLineLineNo: Record "Service Item Line";
        ServiceItemLineNo: Integer;
    begin
        // serviceItemLine.
        serviceItemLine.Reset();
        serviceItemLine.SetRange("Document Type", serviceHeader."Document Type");
        serviceItemLine.SetRange("Document No.", serviceHeader."No.");
        serviceItemLine.SetRange(orderLineNo, salesLine."Line No.");

        if serviceItemLine.FindFirst() then begin
            serviceItemLine."Item No." := salesLine."No.";
            serviceItemLine.Validate("Item No.");
            serviceItemLine.Modify(true);
        end else begin
            serviceItemLineLineNo.Reset();
            serviceItemLineLineNo.SetRange("Document Type", serviceHeader."Document Type");
            serviceItemLineLineNo.SetRange("Document No.", serviceHeader."No.");
            if serviceItemLineLineNo.FindLast() then
                ServiceItemLineNo := serviceItemLineLineNo."Line No." + 10000
            else
                ServiceItemLineNo := 10000;

            serviceItemLine.Init();
            serviceItemLine."Document No." := serviceHeader."No.";
            serviceItemLine."Document Type" := serviceHeader."Document Type";
            serviceItemLine."Line No." := ServiceItemLineNo;
            serviceItemLine.orderLineNo := salesLine."Line No.";

            serviceItemLine."Item No." := salesLine."No.";
            serviceItemLine.Validate("Item No.");
            serviceItemLine.Insert(true);
        end;
        // this.createServiceLine(salesLine, serviceHeader, serviceItemLine);

    end;

    procedure createServiceLine(var salesLine: Record "Sales Line"; var serviceHeader: record "Service Header"; var serviceItemLine: Record "Service Item Line")
    var
        serviceLine: Record "Service Line";
        serviceLineLineNo: Record "Service Line";
        ServiceLineNo: Integer;
    begin
        // serviceItemLine.
        serviceLine.Reset();
        serviceLine.SetRange("Document Type", serviceHeader."Document Type");
        serviceLine.SetRange("Document No.", serviceHeader."No.");
        serviceLine.SetRange(orderLineNo, salesLine."Line No.");

        if serviceLine.FindFirst() then begin
            serviceLine."No." := salesLine."No.";
            serviceLine."Service Item Line No." := serviceItemLine."Line No.";
            serviceLine.Validate("Line No.");
            serviceLine.Validate("No.");
            serviceLine."Location Code" := salesLine."Location Code";
            serviceLine.Validate("Location Code");
            serviceLine.Quantity := salesLine.Quantity;
            serviceLine.Validate(Quantity);
            serviceLine."Unit of Measure Code" := salesLine."Unit of Measure Code";
            serviceLine.Validate("Unit of Measure Code");
            serviceLine.orderLineNo := salesLine."Line No.";
            serviceLine.Modify();
        end else begin
            serviceLineLineNo.Reset();
            serviceLineLineNo.SetRange("Document Type", serviceHeader."Document Type");
            serviceLineLineNo.SetRange("Document No.", serviceHeader."No.");
            if serviceLineLineNo.FindLast() then
                ServiceLineNo := serviceLineLineNo."Line No." + 10000
            else
                ServiceLineNo := 10000;

            serviceLine.Init();
            serviceLine."Document No." := serviceHeader."No.";
            serviceLine."Document Type" := serviceHeader."Document Type";
            serviceLine."Service Item Line No." := serviceItemLine."Line No.";
            serviceLine.Validate("Line No.");
            serviceLine."Line No." := ServiceLineNo;
            serviceLine.Type := serviceLine.Type::Item;
            serviceLine.Validate(Type);
            serviceLine."No." := salesLine."No.";
            serviceLine."Customer No." := serviceHeader."Customer No.";
            serviceLine.Validate("Customer No.");
            serviceLine.Validate("No.");
            serviceLine."Location Code" := salesLine."Location Code";
            serviceLine.Validate("Location Code");
            serviceLine.Quantity := salesLine.Quantity;
            serviceLine.Validate(Quantity);
            serviceLine."Unit of Measure Code" := salesLine."Unit of Measure Code";
            serviceLine.Validate("Unit of Measure Code");
            serviceLine.orderLineNo := salesLine."Line No.";
            serviceLine.Insert(true);
        end;

    end;

    //rule to prevent item from service line to enter requisition worksheet
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Line Invt. Profile", OnTransServLineToProfileOnBeforeProcessLine, '', false, false)]
    local procedure "Service Line Invt. Profile_OnTransServLineToProfileOnBeforeProcessLine"(ServiceLine: Record "Service Line"; var ShouldProcess: Boolean; var Item: Record Item)
    var
        serviceHeader: Record "Service Header";
    begin
        if serviceHeader.Get(serviceHeader."Document Type"::Order, ServiceLine."Document No.") then begin
            if serviceHeader."Sales Order Reference" <> '' then
                ShouldProcess := false;
        end;
    end;



    [EventSubscriber(ObjectType::Report, Report::"Create Contract Service Orders", OnBeforeModifyServiceHeader, '', false, false)]
    local procedure "Create Contract Service Orders_OnBeforeModifyServiceHeader"(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line")
    var
        NomDuProprietaire: Text;
    begin
        ServiceHeader."Reference Supp." := ServiceContractHeader."Reference Supp.";
        NomDuProprietaire := ServiceContractHeader.GetNomduProprietaire();
        ServiceHeader.SetNomduProprietaire(NomDuProprietaire);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", OnAfterFinalizeInvoiceDocument, '', false, false)]
    local procedure "Serv-Documents Mgt._OnAfterFinalizeInvoiceDocument"(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceHeader: Record "Service Header"; var PServInvHeader: Record "Service Invoice Header")
    var
        NomDuProprietaire: Text;
    begin
        if ServiceHeader."Document Type" = ServiceHeader."Document Type"::"Credit Memo" then
            exit;
        PServInvHeader."Reference Supp." := ServiceHeader."Reference Supp.";
        NomDuProprietaire := ServiceHeader.GetNomduProprietaire();
        PServInvHeader.SetNomduProprietaire(NomDuProprietaire);//here
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", OnAfterFinalizeCrMemoDocument, '', false, false)]
    local procedure "Serv-Documents Mgt._OnAfterFinalizeCrMemoDocument"(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; ServiceHeader: Record "Service Header"; var PServCrMemoHeader: Record "Service Cr.Memo Header")
    var
        NomDuProprietaire: Text;
    begin
        if ServiceHeader."Document Type" in [ServiceHeader."Document Type"::Order, ServiceHeader."Document Type"::"Invoice"] then
            exit;
        PServCrMemoHeader."Reference Supp." := ServiceHeader."Reference Supp.";
        NomDuProprietaire := ServiceHeader.GetNomduProprietaire();
        PServCrMemoHeader.SetNomduProprietaire(NomDuProprietaire);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ServContractManagement, OnBeforeInsertServiceHeader, '', false, false)]
    local procedure ServContractManagement_OnBeforeInsertServiceHeader(var ServiceHeader: Record "Service Header"; var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceHeader."Reference Supp." := ServiceContractHeader."Reference Supp.";
        ServiceContractHeader.CalcFields("Nom du Proprietaire");
        ServiceHeader."Nom du Proprietaire" := ServiceContractHeader."Nom du Proprietaire";
    end;


    //service line table mapping events
    // OnBeforeInsertServiceItemLine
    [EventSubscriber(ObjectType::Report, Report::"Create Contract Service Orders", OnBeforeInsertServiceItemLine, '', false, false)]
    local procedure "Create Contract Service Orders_OnBeforeInsertServiceItemLine"(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line")
    begin
        ServiceItemLine."Description Supp." := ServiceContractLine."Description Supp.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ServContractManagement, OnBeforeServLineInsert, '', false, false)]
    local procedure ServContractManagement_OnBeforeServLineInsert(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header")
    begin
    end;


    var
        ConfirmManagement: Codeunit "Confirm Management";
}
