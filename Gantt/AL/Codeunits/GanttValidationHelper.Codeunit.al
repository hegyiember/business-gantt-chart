codeunit 71891732 "DGOG Gantt Validation Helper"
{
    procedure ValidateSetup(var GanttSetup: Record "DGOG Gantt Setup")
    var
        GanttView: Record "DGOG Gantt View";
        MappingLine: Record "DGOG Gantt Mapping Line";
    begin
        if not GanttSetup.Active then
            Error('Gantt setup %1 is not active.', GanttSetup."ID");

        GanttView.SetRange("Setup ID", GanttSetup."ID");
        if not GanttView.FindFirst() then
            Error('Gantt setup %1 must contain at least one view.', GanttSetup."ID");

        repeat
            ValidateView(GanttSetup, GanttView);
        until GanttView.Next() = 0;

        MappingLine.SetRange("Setup ID", GanttSetup."ID");
        if not MappingLine.FindFirst() then
            Error('Gantt setup %1 must contain at least one mapping line.', GanttSetup."ID");
    end;

    procedure ValidateView(GanttSetup: Record "DGOG Gantt Setup"; GanttView: Record "DGOG Gantt View")
    var
        MappingLine: Record "DGOG Gantt Mapping Line";
        DetailLine: Record "DGOG Gantt Detail Line";
    begin
        MappingLine.SetRange("Setup ID", GanttSetup."ID");
        MappingLine.SetRange("View Code", GanttView."View Code");
        if not MappingLine.FindFirst() then
            Error('View %1 on setup %2 does not contain any mapping lines.', GanttView."View Code", GanttSetup."ID");

        repeat
            ValidateMappingLine(MappingLine);
            ValidateGroupingLines(MappingLine);
        until MappingLine.Next() = 0;

        DetailLine.SetRange("Setup ID", GanttSetup."ID");
        DetailLine.SetRange("View Code", GanttView."View Code");
        if DetailLine.FindSet() then
            repeat
                ValidateDetailLine(DetailLine);
            until DetailLine.Next() = 0;
    end;

    procedure ValidateMappingLine(MappingLine: Record "DGOG Gantt Mapping Line")
    begin
        EnsureTableExists(MappingLine."Source Table ID");
        EnsureFieldExists(MappingLine."Source Table ID", MappingLine."Key Field ID");
        EnsureParentRelations(MappingLine);

        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Description Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Start Date Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."End Date Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Due Date Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Start Decimal Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."End Decimal Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Status Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Sequence Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Grouping Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Context Identity Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Resource Group Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Dependency Target Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Dependency Order Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Aggregation Value Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Aggregation Capacity Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Conflict Group Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Progress Override Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Color Override Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Label Override Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Tooltip Title Field ID");
    end;

    procedure ValidateDetailLine(DetailLine: Record "DGOG Gantt Detail Line")
    var
        MappingLine: Record "DGOG Gantt Mapping Line";
    begin
        if not MappingLine.Get(DetailLine."Setup ID", DetailLine."View Code", DetailLine."Mapping Line No.") then
            Error('Detail line %1 references missing mapping line %2 in view %3 setup %4.', DetailLine."Line No.", DetailLine."Mapping Line No.", DetailLine."View Code", DetailLine."Setup ID");

        EnsureFieldExists(MappingLine."Source Table ID", DetailLine."Field ID");
    end;

    local procedure ValidateGroupingLines(MappingLine: Record "DGOG Gantt Mapping Line")
    var
        GroupingLine: Record "DGOG Gantt Grouping Line";
    begin
        GroupingLine.SetRange("Setup ID", MappingLine."Setup ID");
        GroupingLine.SetRange("View Code", MappingLine."View Code");
        GroupingLine.SetRange("Mapping Line No.", MappingLine."Line No.");
        if not GroupingLine.FindSet() then
            exit;

        repeat
            EnsureFieldExists(MappingLine."Source Table ID", GroupingLine."Group Field ID");
        until GroupingLine.Next() = 0;
    end;

    procedure ResolveViewCode(SetupId: Integer; RequestedViewCode: Code[20]): Code[20]
    var
        GanttSetup: Record "DGOG Gantt Setup";
        GanttView: Record "DGOG Gantt View";
    begin
        if RequestedViewCode <> '' then
            exit(RequestedViewCode);

        GanttSetup.Get(SetupId);
        if GanttSetup."Default View Code" <> '' then
            exit(GanttSetup."Default View Code");

        GanttView.SetRange("Setup ID", SetupId);
        GanttView.SetRange("Is Default", true);
        if GanttView.FindFirst() then
            exit(GanttView."View Code");

        GanttView.SetRange("Is Default");
        if GanttView.FindFirst() then
            exit(GanttView."View Code");

        exit('');
    end;

    procedure EnsureTableExists(TableId: Integer)
    var
        AllObjects: Record AllObjWithCaption;
    begin
        if TableId = 0 then
            Error('A source table ID is required.');

        AllObjects.SetRange("Object Type", AllObjects."Object Type"::Table);
        AllObjects.SetRange("Object ID", TableId);
        if not AllObjects.FindFirst() then
            Error('Table %1 does not exist or is not accessible.', TableId);
    end;

    procedure EnsureFieldExists(TableId: Integer; FieldId: Integer)
    var
        FieldMeta: Record Field;
    begin
        if FieldId = 0 then
            Error('A required field ID is missing for table %1.', TableId);
        if not FieldMeta.Get(TableId, FieldId) then
            Error('Field %1 does not exist on table %2.', FieldId, TableId);
    end;

    procedure EnsureFieldIfSpecified(TableId: Integer; FieldId: Integer)
    begin
        if FieldId = 0 then
            exit;
        EnsureFieldExists(TableId, FieldId);
    end;

    local procedure EnsureParentRelations(MappingLine: Record "DGOG Gantt Mapping Line")
    var
        ParentMappingLine: Record "DGOG Gantt Mapping Line";
        MappingRelation: Record "DGOG Gantt Mapping Relation";
        ChildFieldMeta: Record Field;
        ParentFieldMeta: Record Field;
    begin
        MappingRelation.SetRange("Setup ID", MappingLine."Setup ID");
        MappingRelation.SetRange("View Code", MappingLine."View Code");
        MappingRelation.SetRange("Child Line No.", MappingLine."Line No.");

        if MappingLine."Parent Line No." = 0 then begin
            if MappingRelation.FindFirst() then
                Error('Parent field mappings must be blank on root mapping line %1.', MappingLine."Line No.");
            exit;
        end;

        if not ParentMappingLine.Get(MappingLine."Setup ID", MappingLine."View Code", MappingLine."Parent Line No.") then
            Error('Parent mapping line %1 does not exist for mapping line %2.', MappingLine."Parent Line No.", MappingLine."Line No.");

        if not MappingRelation.FindSet() then
            Error('At least one parent field mapping is required on non-root mapping line %1.', MappingLine."Line No.");

        repeat
            if MappingRelation."Parent Line No." <> MappingLine."Parent Line No." then
                Error('Parent field mapping %1 must point to parent line %2 for mapping line %3.', MappingRelation."Line No.", MappingLine."Parent Line No.", MappingLine."Line No.");

            if MappingRelation."Child Table ID" <> MappingLine."Source Table ID" then
                Error('Current-line table on parent field mapping %1 must be table %2.', MappingRelation."Line No.", MappingLine."Source Table ID");

            if MappingRelation."Parent Table ID" <> ParentMappingLine."Source Table ID" then
                Error('Parent-line table on parent field mapping %1 must be table %2.', MappingRelation."Line No.", ParentMappingLine."Source Table ID");

            EnsureFieldExists(MappingLine."Source Table ID", MappingRelation."Child Field ID");
            EnsureFieldExists(ParentMappingLine."Source Table ID", MappingRelation."Parent Field ID");

            ChildFieldMeta.Get(MappingLine."Source Table ID", MappingRelation."Child Field ID");
            ParentFieldMeta.Get(ParentMappingLine."Source Table ID", MappingRelation."Parent Field ID");

            if ChildFieldMeta.Type <> ParentFieldMeta.Type then
                Error(
                  'Current-line field %1 on table %2 must have the same type as parent-line field %3 on table %4.',
                  MappingRelation."Child Field ID",
                  MappingLine."Source Table ID",
                  MappingRelation."Parent Field ID",
                  ParentMappingLine."Source Table ID");
        until MappingRelation.Next() = 0;
    end;

    procedure HasField(TableId: Integer; FieldId: Integer): Boolean
    var
        FieldMeta: Record Field;
    begin
        if (TableId = 0) or (FieldId = 0) then
            exit(false);
        exit(FieldMeta.Get(TableId, FieldId));
    end;

    procedure GetFieldCaption(TableId: Integer; FieldId: Integer): Text
    var
        FieldMeta: Record Field;
    begin
        if not FieldMeta.Get(TableId, FieldId) then
            exit(Format(FieldId));
        exit(FieldMeta."Field Caption");
    end;

    procedure GetFieldValueAsText(var SourceRef: RecordRef; FieldId: Integer): Text
    var
        SourceField: FieldRef;
    begin
        if FieldId = 0 then
            exit('');
        SourceField := SourceRef.Field(FieldId);
        exit(Format(SourceField.Value, 0, 9));
    end;

    procedure GetFieldValueAsDisplayText(var SourceRef: RecordRef; FieldId: Integer): Text
    var
        SourceField: FieldRef;
        OrdinalValue: Integer;
        RawValue: Text;
        OptionCaptions: Text;
    begin
        if FieldId = 0 then
            exit('');

        SourceField := SourceRef.Field(FieldId);
        RawValue := Format(SourceField.Value, 0, 9);
        if RawValue = '' then
            exit('');

        if SourceField.IsEnum() then begin
            if Evaluate(OrdinalValue, RawValue) then
                exit(SourceField.GetEnumValueCaptionFromOrdinalValue(OrdinalValue));
            exit(RawValue);
        end;

        OptionCaptions := SourceField.OptionCaption;
        if (OptionCaptions <> '') and Evaluate(OrdinalValue, RawValue) then
            exit(SelectStr(OrdinalValue + 1, OptionCaptions));

        exit(RawValue);
    end;

    procedure GetFieldValueAsIso(var SourceRef: RecordRef; FieldId: Integer): Text
    var
        FieldMeta: Record Field;
        SourceField: FieldRef;
        DateValue: Date;
        DateTimeValue: DateTime;
        TimeValue: Time;
    begin
        if FieldId = 0 then
            exit('');
        SourceField := SourceRef.Field(FieldId);
        if not FieldMeta.Get(SourceRef.Number, FieldId) then
            exit(Format(SourceField.Value, 0, 9));

        case FieldMeta.Type of
            FieldMeta.Type::Date:
                begin
                    DateValue := SourceField.Value;
                    if DateValue = 0D then
                        exit('');
                    exit(Format(CreateDateTime(DateValue, 0T), 0, 9));
                end;
            FieldMeta.Type::DateTime:
                begin
                    DateTimeValue := SourceField.Value;
                    if DateTimeValue = 0DT then
                        exit('');
                    exit(Format(DateTimeValue, 0, 9));
                end;
            FieldMeta.Type::Time:
                begin
                    TimeValue := SourceField.Value;
                    exit(Format(CreateDateTime(Today, TimeValue), 0, 9));
                end;
            else
                exit(Format(SourceField.Value, 0, 9));
        end;
    end;

    procedure GetFieldDateTime(var SourceRef: RecordRef; FieldId: Integer): DateTime
    var
        FieldMeta: Record Field;
        SourceField: FieldRef;
        DateValue: Date;
        DateTimeValue: DateTime;
        TimeValue: Time;
    begin
        if FieldId = 0 then
            exit(0DT);
        SourceField := SourceRef.Field(FieldId);
        if not FieldMeta.Get(SourceRef.Number, FieldId) then
            exit(0DT);

        case FieldMeta.Type of
            FieldMeta.Type::Date:
                begin
                    DateValue := SourceField.Value;
                    if DateValue = 0D then
                        exit(0DT);
                    exit(CreateDateTime(DateValue, 0T));
                end;
            FieldMeta.Type::DateTime:
                begin
                    DateTimeValue := SourceField.Value;
                    exit(DateTimeValue);
                end;
            FieldMeta.Type::Time:
                begin
                    TimeValue := SourceField.Value;
                    exit(CreateDateTime(Today, TimeValue));
                end;
        end;

        exit(0DT);
    end;

    procedure GetFieldDecimal(var SourceRef: RecordRef; FieldId: Integer): Decimal
    var
        SourceField: FieldRef;
        DecimalValue: Decimal;
    begin
        if FieldId = 0 then
            exit(0);
        SourceField := SourceRef.Field(FieldId);
        Evaluate(DecimalValue, Format(SourceField.Value));
        exit(DecimalValue);
    end;

    procedure SetFieldFromText(var SourceRef: RecordRef; FieldId: Integer; NewValueText: Text)
    var
        FieldMeta: Record Field;
        TargetField: FieldRef;
        DateValue: Date;
        DateTimeValue: DateTime;
        DecimalValue: Decimal;
        IntegerValue: Integer;
        BigIntegerValue: BigInteger;
        TimeValue: Time;
        BooleanValue: Boolean;
    begin
        EnsureFieldExists(SourceRef.Number, FieldId);
        FieldMeta.Get(SourceRef.Number, FieldId);
        TargetField := SourceRef.Field(FieldId);

        case FieldMeta.Type of
            FieldMeta.Type::Date:
                begin
                    Clear(DateValue);
                    if (NewValueText <> '') and (not TryParseDateValue(NewValueText, DateValue)) then
                        Error('The value %1 is not a valid date for field %2 on table %3.', NewValueText, FieldId, SourceRef.Number);
                    TargetField.Validate(DateValue);
                end;
            FieldMeta.Type::DateTime:
                begin
                    Clear(DateTimeValue);
                    if (NewValueText <> '') and (not TryParseDateTimeValue(NewValueText, DateTimeValue)) then
                        Error('The value %1 is not a valid date/time for field %2 on table %3.', NewValueText, FieldId, SourceRef.Number);
                    TargetField.Validate(DateTimeValue);
                end;
            FieldMeta.Type::Time:
                begin
                    Clear(TimeValue);
                    if (NewValueText <> '') and (not TryParseTimeValue(NewValueText, TimeValue)) then
                        Error('The value %1 is not a valid time for field %2 on table %3.', NewValueText, FieldId, SourceRef.Number);
                    TargetField.Validate(TimeValue);
                end;
            FieldMeta.Type::Decimal:
                begin
                    Clear(DecimalValue);
                    if NewValueText <> '' then
                        Evaluate(DecimalValue, NewValueText);
                    TargetField.Validate(DecimalValue);
                end;
            FieldMeta.Type::Integer:
                begin
                    Clear(IntegerValue);
                    if NewValueText <> '' then
                        Evaluate(IntegerValue, NewValueText);
                    TargetField.Validate(IntegerValue);
                end;
            FieldMeta.Type::BigInteger:
                begin
                    Clear(BigIntegerValue);
                    if NewValueText <> '' then
                        Evaluate(BigIntegerValue, NewValueText);
                    TargetField.Validate(BigIntegerValue);
                end;
            FieldMeta.Type::Boolean:
                begin
                    Clear(BooleanValue);
                    if NewValueText <> '' then
                        Evaluate(BooleanValue, NewValueText);
                    TargetField.Validate(BooleanValue);
                end;
            else
                TargetField.Validate(NewValueText);
        end;
    end;

    local procedure TryParseDateValue(InputText: Text; var DateValue: Date): Boolean
    var
        ParsedDateTime: DateTime;
    begin
        if Evaluate(DateValue, InputText) then
            exit(true);
        if TryParseIsoDateValue(InputText, DateValue) then
            exit(true);
        if TryParseDateTimeValue(InputText, ParsedDateTime) then begin
            DateValue := DT2Date(ParsedDateTime);
            exit(true);
        end;
        exit(false);
    end;

    local procedure TryParseDateTimeValue(InputText: Text; var DateTimeValue: DateTime): Boolean
    var
        ParsedDate: Date;
        ParsedTime: Time;
    begin
        if Evaluate(DateTimeValue, InputText) then
            exit(true);
        if TryParseIsoDateTimeParts(InputText, ParsedDate, ParsedTime) then begin
            DateTimeValue := CreateDateTime(ParsedDate, ParsedTime);
            exit(true);
        end;
        exit(false);
    end;

    local procedure TryParseTimeValue(InputText: Text; var TimeValue: Time): Boolean
    var
        ParsedDate: Date;
    begin
        if Evaluate(TimeValue, InputText) then
            exit(true);
        if TryParseIsoTimeValue(InputText, TimeValue) then
            exit(true);
        if TryParseIsoDateTimeParts(InputText, ParsedDate, TimeValue) then
            exit(true);
        exit(false);
    end;

    local procedure TryParseIsoDateValue(InputText: Text; var DateValue: Date): Boolean
    begin
        if StrLen(InputText) < 10 then
            exit(false);
        exit(TryCreateIsoDate(CopyStr(InputText, 1, 10), DateValue));
    end;

    local procedure TryParseIsoDateTimeParts(InputText: Text; var DateValue: Date; var TimeValue: Time): Boolean
    begin
        if StrLen(InputText) < 19 then
            exit(false);
        if not TryCreateIsoDate(CopyStr(InputText, 1, 10), DateValue) then
            exit(false);
        if (CopyStr(InputText, 11, 1) <> 'T') and (CopyStr(InputText, 11, 1) <> ' ') then
            exit(false);
        exit(TryParseIsoTimeValue(CopyStr(InputText, 12), TimeValue));
    end;

    local procedure TryParseIsoTimeValue(InputText: Text; var TimeValue: Time): Boolean
    var
        TimeText: Text;
        HourValue: Integer;
        MinuteValue: Integer;
        SecondValue: Integer;
    begin
        TimeText := InputText;
        if (StrLen(TimeText) >= 1) and (CopyStr(TimeText, 1, 1) = 'T') then
            TimeText := CopyStr(TimeText, 2);
        if StrLen(TimeText) < 8 then
            exit(false);
        if (CopyStr(TimeText, 3, 1) <> ':') or (CopyStr(TimeText, 6, 1) <> ':') then
            exit(false);
        if not Evaluate(HourValue, CopyStr(TimeText, 1, 2)) then
            exit(false);
        if not Evaluate(MinuteValue, CopyStr(TimeText, 4, 2)) then
            exit(false);
        if not Evaluate(SecondValue, CopyStr(TimeText, 7, 2)) then
            exit(false);
        exit(Evaluate(TimeValue, CopyStr(TimeText, 1, 8)));
    end;

    local procedure TryCreateIsoDate(InputText: Text; var DateValue: Date): Boolean
    var
        YearValue: Integer;
        MonthValue: Integer;
        DayValue: Integer;
    begin
        if StrLen(InputText) < 10 then
            exit(false);
        if (CopyStr(InputText, 5, 1) <> '-') or (CopyStr(InputText, 8, 1) <> '-') then
            exit(false);
        if not Evaluate(YearValue, CopyStr(InputText, 1, 4)) then
            exit(false);
        if not Evaluate(MonthValue, CopyStr(InputText, 6, 2)) then
            exit(false);
        if not Evaluate(DayValue, CopyStr(InputText, 9, 2)) then
            exit(false);
        DateValue := DMY2Date(DayValue, MonthValue, YearValue);
        exit(true);
    end;

    procedure SetFieldFilterFromText(var SourceRef: RecordRef; FieldId: Integer; FilterText: Text)
    var
        FieldMeta: Record Field;
        SourceField: FieldRef;
        DateValue: Date;
        DateTimeValue: DateTime;
        DecimalValue: Decimal;
        IntegerValue: Integer;
        BigIntegerValue: BigInteger;
        TimeValue: Time;
    begin
        if (FieldId = 0) or (FilterText = '') then
            exit;

        FieldMeta.Get(SourceRef.Number, FieldId);
        SourceField := SourceRef.Field(FieldId);

        case FieldMeta.Type of
            FieldMeta.Type::Date:
                begin
                    Evaluate(DateValue, FilterText);
                    SourceField.SetRange(DateValue);
                end;
            FieldMeta.Type::DateTime:
                begin
                    Evaluate(DateTimeValue, FilterText);
                    SourceField.SetRange(DateTimeValue);
                end;
            FieldMeta.Type::Time:
                begin
                    Evaluate(TimeValue, FilterText);
                    SourceField.SetRange(TimeValue);
                end;
            FieldMeta.Type::Decimal:
                begin
                    Evaluate(DecimalValue, FilterText);
                    SourceField.SetRange(DecimalValue);
                end;
            FieldMeta.Type::Integer:
                begin
                    Evaluate(IntegerValue, FilterText);
                    SourceField.SetRange(IntegerValue);
                end;
            FieldMeta.Type::BigInteger:
                begin
                    Evaluate(BigIntegerValue, FilterText);
                    SourceField.SetRange(BigIntegerValue);
                end;
            else
                SourceField.SetRange(FilterText);
        end;
    end;
}