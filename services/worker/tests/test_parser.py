from app.main import parse_payroll_text


def test_parser_notas_horas():
    text = """
    ROL DE PAGOS MARZO 2026
    NOTAS HORAS
    -496.45 HORAS SALDO ANTERIOR
    128.16 HORAS COMPENSANDAS
    -368.29 SALDO ACTUAL
    TOTALES
    """
    result = parse_payroll_text(text)
    assert "debt_hours" in result["fields"]
    assert result["fields"]["debt_hours"]["value"].startswith("-496")
    assert "paid_hours" in result["fields"]
    assert result["period"] == (2026, 3)
