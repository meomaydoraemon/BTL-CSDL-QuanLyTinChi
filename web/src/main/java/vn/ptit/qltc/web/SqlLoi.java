package vn.ptit.qltc.web;

import java.sql.SQLException;

import org.springframework.dao.DataAccessException;

/** Lấy nguyên văn thông báo tiếng Việt mà stored procedure ném ra (THROW 500xx). */
public final class SqlLoi {

    private SqlLoi() {
    }

    public static String thongBao(DataAccessException ex) {
        Throwable t = ex;
        while (t != null) {
            if (t instanceof SQLException sql && sql.getMessage() != null) {
                return sql.getMessage();
            }
            t = t.getCause();
        }
        return "Có lỗi xảy ra, vui lòng thử lại.";
    }
}
