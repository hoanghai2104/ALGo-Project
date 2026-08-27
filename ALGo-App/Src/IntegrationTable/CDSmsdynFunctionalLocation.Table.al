table 50201 "CDS msdyn_FunctionalLocation"
{
    ExternalName = 'msdyn_functionallocation';
    TableType = CRM;
    Description = '';

    fields
    {
        field(1; msdyn_FunctionalLocationId; GUID)
        {
            ExternalName = 'msdyn_functionallocationid';
            ExternalType = 'Uniqueidentifier';
            ExternalAccess = Insert;
            Description = 'Identificateur unique des instances d’entité';
            Caption = 'Poste technique';
        }
        field(2; CreatedOn; Datetime)
        {
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
            ExternalAccess = Read;
            Description = 'Date et heure de la création de l’enregistrement.';
            Caption = 'Date de création';
        }
        field(4; ModifiedOn; Datetime)
        {
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
            ExternalAccess = Read;
            Description = 'Date et heure de la modification de l’enregistrement.';
            Caption = 'Date de modification';
        }
        field(25; statecode; Option)
        {
            ExternalName = 'statecode';
            ExternalType = 'State';
            ExternalAccess = Modify;
            Description = 'Statut du poste technique';
            Caption = 'Statut';
            InitValue = " ";
            OptionMembers = " ",Actif,Inactif;
            OptionOrdinalValues = -1, 0, 1;
        }
        field(27; statuscode; Option)
        {
            ExternalName = 'statuscode';
            ExternalType = 'Status';
            Description = 'Raison du statut du poste technique';
            Caption = 'Raison du statut';
            InitValue = " ";
            OptionMembers = " ",Actif,Inactif;
            OptionOrdinalValues = -1, 1, 2;
        }
        field(29; VersionNumber; BigInteger)
        {
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
            ExternalAccess = Read;
            Description = 'Version Number';
            Caption = 'Version Number';
        }
        field(30; ImportSequenceNumber; Integer)
        {
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
            ExternalAccess = Insert;
            Description = 'Numéro séquentiel de l’importation ayant créé cet enregistrement.';
            Caption = 'Numéro séquentiel de l’importation';
        }
        field(31; OverriddenCreatedOn; Date)
        {
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
            ExternalAccess = Insert;
            Description = 'Date et heure de la migration de l’enregistrement.';
            Caption = 'Date de création de l’enregistrement';
        }
        field(32; TimeZoneRuleVersionNumber; Integer)
        {
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            Description = 'Utilisation interne uniquement.';
            Caption = 'Numéro de version de la règle du fuseau horaire';
        }
        field(33; UTCConversionTimeZoneCode; Integer)
        {
            ExternalName = 'utcconversiontimezonecode';
            ExternalType = 'Integer';
            Description = 'Code de fuseau horaire utilisé à la création de l’enregistrement.';
            Caption = 'Code de fuseau horaire pour la conversion UTC';
        }
        field(34; msdyn_Name; Text[60])
        {
            ExternalName = 'msdyn_name';
            ExternalType = 'String';
            Description = 'Champ Nom obligatoire';
            Caption = 'Nom';
        }
        field(35; msdyn_CostCenter; Text[100])
        {
            ExternalName = 'msdyn_costcenter';
            ExternalType = 'String';
            Description = '';
            Caption = 'Centre de coûts';
        }
        field(36; msdyn_EmailAddress; Text[100])
        {
            ExternalName = 'msdyn_emailaddress';
            ExternalType = 'String';
            Description = '';
            Caption = 'Adresse e-mail';
        }
        field(37; msdyn_LocationOpenDate; Date)
        {
            ExternalName = 'msdyn_locationopendate';
            ExternalType = 'DateTime';
            Description = '';
            Caption = 'Date d’ouverture de l’emplacement';
        }
        field(39; msdyn_ParentFunctionalLocation; GUID)
        {
            ExternalName = 'msdyn_parentfunctionallocation';
            ExternalType = 'Lookup';
            Description = '';
            Caption = 'Poste technique parent';
            TableRelation = "CDS msdyn_FunctionalLocation".msdyn_FunctionalLocationId;
        }
        field(40; msdyn_PrimaryTimeZone; Integer)
        {
            ExternalName = 'msdyn_primarytimezone';
            ExternalType = 'Integer';
            Description = '';
            Caption = 'Fuseau horaire principal';
        }
        field(41; msdyn_Sequence; Integer)
        {
            ExternalName = 'msdyn_sequence';
            ExternalType = 'Integer';
            Description = 'Ordre relatif du nœud de l’entité Poste technique dans le contrôle de hiérarchie';
            Caption = 'Séquence';
        }
        field(42; msdyn_ShortName; Text[100])
        {
            ExternalName = 'msdyn_shortname';
            ExternalType = 'String';
            Description = '';
            Caption = 'Nom court';
        }
        field(44; msdyn_ParentFunctionalLocationName; Text[60])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("CDS msdyn_FunctionalLocation".msdyn_Name where(msdyn_FunctionalLocationId = field(msdyn_ParentFunctionalLocation)));
            ExternalName = 'msdyn_parentfunctionallocationname';
            ExternalType = 'String';
            ExternalAccess = Read;
        }
        field(45; msdyn_Address1; Text[250])
        {
            ExternalName = 'msdyn_address1';
            ExternalType = 'String';
            Description = '';
            Caption = 'Rue 1';
        }
        field(46; msdyn_Address2; Text[250])
        {
            ExternalName = 'msdyn_address2';
            ExternalType = 'String';
            Description = 'Rue 2';
            Caption = 'Rue 2';
        }
        field(47; msdyn_Address3; Text[250])
        {
            ExternalName = 'msdyn_address3';
            ExternalType = 'String';
            Description = 'Rue 3';
            Caption = 'Rue 3';
        }
        field(48; msdyn_AddressName; Text[250])
        {
            ExternalName = 'msdyn_addressname';
            ExternalType = 'String';
            Description = 'Nom de l’adresse';
            Caption = 'Nom de l’adresse';
        }
        field(49; msdyn_City; Text[80])
        {
            ExternalName = 'msdyn_city';
            ExternalType = 'String';
            Description = 'Ville';
            Caption = 'Ville';
        }
        field(50; msdyn_Country; Text[80])
        {
            ExternalName = 'msdyn_country';
            ExternalType = 'String';
            Description = 'Pays/Région';
            Caption = 'Pays/Région';
        }
        field(51; msdyn_Latitude; Decimal)
        {
            ExternalName = 'msdyn_latitude';
            ExternalType = 'Double';
            Description = 'Latitude';
            Caption = 'Latitude';
        }
        field(52; msdyn_Longitude; Decimal)
        {
            ExternalName = 'msdyn_longitude';
            ExternalType = 'Double';
            Description = 'Longitude';
            Caption = 'Longitude';
        }
        field(53; msdyn_PostalCode; Text[20])
        {
            ExternalName = 'msdyn_postalcode';
            ExternalType = 'String';
            Description = 'Code postal';
            Caption = 'Code postal';
        }
        field(54; msdyn_StateOrProvince; Text[50])
        {
            ExternalName = 'msdyn_stateorprovince';
            ExternalType = 'String';
            Description = 'Département ou province';
            Caption = 'Département ou province';
        }
        field(55; phma_BusinessCentralCode; Text[100])
        {
            ExternalName = 'phma_businesscentralcode';
            ExternalType = 'String';
            Description = '';
            Caption = 'Business Central Code';
        }
        field(56; ModifiedBy; GUID)
        {
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            ExternalAccess = Read;
            Description = 'Unique identifier of the user who modified the record.';
            Caption = 'Modified By';
            TableRelation = "CRM Systemuser".SystemUserId;
            DataClassification = SystemMetadata;
        }
        field(57; phma_Compte; GUID)
        {
            ExternalName = 'phma_compte';
            ExternalType = 'Lookup';
            Description = '';
            Caption = 'Compte';
            TableRelation = "CRM Account".AccountId;
        }
    }
    keys
    {
        key(PK; msdyn_FunctionalLocationId)
        {
            Clustered = true;
        }
        key(Name; msdyn_Name)
        {
        }
    }
    fieldgroups
    {
        fieldgroup(DropDown; msdyn_Name)
        {
        }
    }
    //in
}