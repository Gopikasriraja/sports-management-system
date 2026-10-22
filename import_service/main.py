from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import pandas as pd
import json
import re
import io

app = FastAPI(title="MRCAS Import Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DEPARTMENTS = {
    'B.Sc Computer Science': ['Artificial Intelligence (AI)', 'Data Science & Analytics (DSA)', 'FinTech & Blockchain (FTB)', 'Cyber Security & Cloud Computing (CSCC)'],
    'BBA': ['General BBA', 'BBA Digital Marketing (BBA DM)'],
    'B.Com': ['Computer Applications (CA)', 'General', 'Professional Accounting (PA)'],
    'Visual Communication': [],
    'Psychology': [],
    'Costume Design & Fashion Technology (CDFT)': [],
}

YEARS = ['1st Year', '2nd Year', '3rd Year', 'PG 1st Year', 'PG 2nd Year']

def validate_mobile(phone: str) -> bool:
    if pd.isna(phone): return False
    cleaned = re.sub(r'[^0-9]', '', str(phone))
    return len(cleaned) >= 10

def validate_email(email: str) -> bool:
    if pd.isna(email): return False
    pattern = r'^[\w\.-]+@[\w\.-]+\.\w+$'
    return re.match(pattern, str(email)) is not None

@app.post("/validate-import")
async def validate_import(file: UploadFile = File(...)):
    contents = await file.read()
    filename = file.filename.lower()
    
    try:
        if filename.endswith('.csv'):
            df = pd.read_csv(io.BytesIO(contents))
        elif filename.endswith('.xlsx'):
            df = pd.read_excel(io.BytesIO(contents))
        elif filename.endswith('.json'):
            df = pd.read_json(io.BytesIO(contents))
        else:
            raise HTTPException(status_code=400, detail="Unsupported file format")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error reading file: {str(e)}")

    # Standardize columns
    column_mapping = {
        col: col.strip().lower() for col in df.columns
    }
    df.rename(columns=column_mapping, inplace=True)
    
    # Required columns basic fuzzy matching logic could be here, for now we expect exact but case-insensitive
    required = ['register number', 'name', 'department', 'academic year']
    missing = [c for c in required if not any(c in col for col in df.columns)]
    if missing:
        return {"error": True, "message": f"Missing required columns: {', '.join(missing)}"}

    # Map generic column names
    col_map_target = {}
    for col in df.columns:
        if 'register' in col: col_map_target['registerNumber'] = col
        elif 'name' in col and 'parent' not in col: col_map_target['name'] = col
        elif 'department' in col and 'sub' not in col: col_map_target['department'] = col
        elif 'sub' in col and 'department' in col: col_map_target['subDepartment'] = col
        elif 'year' in col and 'academic' in col: col_map_target['year'] = col
        elif 'year' in col and 'admission' in col: col_map_target['admissionYear'] = col
        elif 'gender' in col: col_map_target['gender'] = col
        elif 'birth' in col or 'dob' in col: col_map_target['dateOfBirth'] = col
        elif 'phone' in col or 'mobile' in col and 'parent' not in col: col_map_target['phone'] = col
        elif 'email' in col: col_map_target['email'] = col
        elif 'sport' in col: col_map_target['sport'] = col
        
    valid_records = []
    invalid_records = []
    duplicate_records = []
    
    seen_registers = set()
    
    for idx, row in df.iterrows():
        record = {}
        issues = []
        
        reg_no = str(row.get(col_map_target.get('registerNumber', ''), '')).strip()
        dept = str(row.get(col_map_target.get('department', ''), '')).strip()
        sub_dept = str(row.get(col_map_target.get('subDepartment', ''), '')).strip()
        year = str(row.get(col_map_target.get('year', ''), '')).strip()
        phone = str(row.get(col_map_target.get('phone', ''), '')).strip()
        email = str(row.get(col_map_target.get('email', ''), '')).strip()
        
        # Auto-map CDFT
        if dept.lower() in ['costume design & fashion technology', 'cdft']:
            dept = 'Costume Design & Fashion Technology (CDFT)'
            sub_dept = ''
        
        
        if not reg_no or reg_no == 'nan':
            issues.append("Register Number missing")
        elif reg_no in seen_registers:
            issues.append(f"Duplicate Register Number: {reg_no}")
        else:
            seen_registers.add(reg_no)
            
        if dept not in DEPARTMENTS:
            issues.append(f"Invalid Department: {dept}")
        else:
            if DEPARTMENTS[dept] and sub_dept not in DEPARTMENTS[dept]:
                issues.append(f"Invalid Sub Department '{sub_dept}' for {dept}")
                
        if year not in YEARS:
            issues.append(f"Invalid Academic Year: {year}")
            
        if not validate_mobile(phone):
            issues.append("Invalid Mobile Number format")
            
        if email and email != 'nan' and not validate_email(email):
            issues.append("Invalid Email format")
            
        raw_record = {k: (str(v) if pd.notna(v) else "") for k, v in row.items()}
            
        if any("Duplicate" in i for i in issues):
            raw_record['_issues'] = issues
            duplicate_records.append(raw_record)
        elif issues:
            raw_record['_issues'] = issues
            invalid_records.append(raw_record)
        else:
            valid_record = {
                "registerNumber": reg_no,
                "name": str(row.get(col_map_target.get('name', ''), '')).strip(),
                "department": dept,
                "subDepartment": sub_dept if sub_dept != 'nan' else '',
                "year": year,
                "admissionYear": str(row.get(col_map_target.get('admissionYear', ''), '')).strip(),
                "gender": str(row.get(col_map_target.get('gender', ''), '')).strip(),
                "dateOfBirth": str(row.get(col_map_target.get('dateOfBirth', ''), '')).strip(),
                "phone": phone,
                "email": email if email != 'nan' else '',
                "sports": [s.strip() for s in str(row.get(col_map_target.get('sport', ''), '')).split(',') if s.strip() and s.strip() != 'nan']
            }
            valid_records.append(valid_record)
            
    return {
        "error": False,
        "valid_records": valid_records,
        "invalid_records": invalid_records,
        "duplicate_records": duplicate_records,
        "stats": {
            "total": len(df),
            "valid": len(valid_records),
            "invalid": len(invalid_records),
            "duplicates": len(duplicate_records)
        }
    }
