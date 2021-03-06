--EXCEPTION
--에러 발생시 프로그램을 종료시키지 않고
--해당 예외에 대해 다른 로직을 실행 시킬 수 있게 끔 처리한다.

--예외가 발생했는데 예외처리가 없는 경우 : pl/sql 블록이 에러와 함계 종료된다
--여러건의 SELECT 결과가 존재하는 상황에서 스칼라 변수에 값을 넣는 상황

--emp 테이블에서 사원 이름을 조회
SET SERVEROUTPUT ON;
DECLARE
    --사원 이름을 저장할 수 있는 변수
    v_ename emp.ename%TYPE;
BEGIN
    --14건의 select 결과가 나오는 SQL --> 스칼라 변수에 저장이 불가하다
    SELECT ename
    INTO v_ename
    FROM emp;
EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('여러건의 select 결과가 존재');
    WHEN OTHERS THEN
        dbms_output.put_line('WHEN OTHERS');
END;
/

--사용자정의 예외

-- 오라클에서 사전에 정의한 예외 의외에도 개발자가 해당 사이트에서 비지니스 로직으로
-- 정의한 예외를 생성, 사용할 수 있따.
-- 예를 들어 SELECT 결과가 없는 상황에서 오라클에서는 NO_DATA_FOUND 예외를 던지면
-- 해당 예외를 잡아 NO_EMP라는 개발자가 정의한 예외로 재정의 하여 예외를 던질 수 있다.

DECLARE
    -- emp 테이블 조회 결과가 없을떄 사용할 사용자 정의 예외
    -- 예외명 EXEPTION;
    no_emp EXCEPTION;
    v_ename emp.ename%TYPE;
BEGIN
    -- NO_ DATA_FOUND
    BEGIN
        SELECT ename
        INTO V_ename
        FROM emp
        WHERE empno = 7000;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE no_emp; -- java throw new No_EmpException()
    END;
EXCEPTION
    WHEN no_emp THEN
    dbms_output.put_line('NO_EMP');
END;
/

--사번을 입력받아서 해당 직원의 이름을 리턴하는 함수
-- getEmpEname(7369) --> SMITH

CREATE OR REPLACE FUNCTION getEmpName (p_empno emp.empno%TYPE)
RETURN VARCHAR2 IS
--선언부
    v_ename emp. ename%TYPE;
BEGIN
    SELECT ename
    INTO v_ename
    FROM emp
    WHERE empno = p_empno;
    
    RETURN v_ename;
    
END;
/

SELECT getempname (7369)
FROM dual;

SELECT getempname (empno)
FROM emp;

CREATE OR REPLACE FUNCTION getdeptname (p_deptno dept.deptno%TYPE)
RETURN VARCHAR2 IS
    v_dname DEPT.DNAME%TYPE;
BEGIN
    SELECT dname
    INTO v_dname
    FROM dept
    WHERE deptno = p_deptno;
    
    RETURN v_dname;

END;
/

--cache : 20
--데이터 분포도 :
--deptno (중복 발생가능) : 분포도가 좋지 못하다
--empno (중복이 없다) : 분포도가 좋다

--emp 테이블의 데이터가 100만건인 경우
--100건 중에서 deptno의 종류는 4건 (4~10)

SELECT getdeptname (10) 
FROM dual;

SELECT getdeptname (deptno) dname, --4가지 
       getEmpName (empno) ename   --row 수만큼 데이터가 존재
FROM emp;

--------------------------------------------------
CREATE OR REPLACE FUNCTION indent (p_lv NUMBER, p_dname VARCHAR2)
RETURN VARCHAR2 IS
    v_dname VARCHAR2(200);
BEGIN
    SELECT LPAD (' ', (p_lv -1) *4, ' ' ) || p_dname
    INTO v_dname
    FROM dual;
    
    RETURN v_dname;
END;
/

SELECT deptcd, LPAD (' ',(level -1) * 4, ' ' ) || deptnm deptnm
FROM dept_h
START WITH p_deptcd IS NULL
CONNECT BY PRIOR deptcd = p_deptcd;

SELECT deptcd, indent (level, deptnm )deptnm
FROM dept_h
START WITH p_deptcd IS NULL
CONNECT BY PRIOR deptcd = p_deptcd;
-----------------------------------------

SELECT *
FROM users;

-- users 테이블의 비밀번호 컬럼이 변경이 생겼을 때
--기존에 사용하던 비밀번호 컬럼 이력을 관리하기 위한 테이블
CREATE TABLE users_history(
    userid VARCHAR2 (20),
    pass VARCHAR2 (100),
    mod_dt date
);

CREATE OR REPLACE TRIGGER make_history
    --timing
    BEFORE UPDATE ON USERS
    FOR EACH ROW -- 행트리거, 행의 변경이 있을 때마다 실행한다
    -- 현재 데이터 참조 : OLD
    -- 갱신 데이터 참조 : NEW
    
    BEGIN
        --users 테이블의 pass 컬럼을 변경할 때 trigger 실행
        IF :OLD.pass !=:NEW.pass THEN
            INSERT INTO users_history
                VALUES (:OLD.userid , :OLD.pass, sysdate);
        END IF;
        -- 다른 컬럼에 대해서는 무시한다
    END;
/
drop trigger make_history;
--USERS 테이블의 PASS 컬럼을 변경 했을 때
--TRIGGER에 의해서 users_histoy 테이블에 이력이 생성되는지 확인
SELECT *
FROM users_history;

UPDATE USERS SET pass = '1234'
WHERE userid = 'brown';

SELECT *
FROM users_history;

--INSERT USERS_HISTORY....
--UPDATE USERS....