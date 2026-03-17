import streamlit as st
import pandas as pd
import mysql.connector
import plotly.express as px


st.set_page_config(
    page_title="Clicsalud — Indicadores de Calidad IPS",
    page_icon="🏥",
    layout="wide"
)


@st.cache_resource
def get_connection():
    return mysql.connector.connect(
        host     = "172.23.112.1",
        user     = "root",
        password = "",  
        database = "clicsalud_ips",
        port= '3306'
    )

@st.cache_data
def run_query(query):
    conn = get_connection()
    return pd.read_sql(query, conn)


st.title("🏥 Clicsalud — Indicadores de Calidad IPS")
st.markdown("Dashboard basado en datos del Ministerio de Salud de Colombia")
st.divider()


col1, col2, col3, col4 = st.columns(4)

total_ips        = run_query("SELECT COUNT(*) AS n FROM ips")
total_deptos     = run_query("SELECT COUNT(*) AS n FROM departamento")
total_resultados = run_query("SELECT COUNT(*) AS n FROM resultado")
total_munis      = run_query("SELECT COUNT(*) AS n FROM municipio")

col1.metric("Total IPS",          f"{total_ips['n'][0]:,}")
col2.metric("Departamentos",      f"{total_deptos['n'][0]:,}")
col3.metric("Municipios",         f"{total_munis['n'][0]:,}")
col4.metric("Registros",          f"{total_resultados['n'][0]:,}")

st.divider()


st.subheader("📊 Promedio de resultados por departamento")

q1 = """
SELECT
    d.nombre_departamento           AS departamento,
    ROUND(AVG(r.valor), 2)          AS promedio_indicador
FROM resultado r
JOIN ips          i  ON r.id_ips          = i.id_ips
JOIN municipio    m  ON i.id_municipio    = m.id_municipio
JOIN departamento d  ON m.id_departamento = d.id_departamento
GROUP BY d.nombre_departamento
ORDER BY promedio_indicador DESC
"""
df1 = run_query(q1)

fig1 = px.bar(
    df1,
    x             = "departamento",
    y             = "promedio_indicador",
    color         = "promedio_indicador",
    color_continuous_scale = "Blues",
    labels        = {"promedio_indicador": "Promedio", "departamento": "Departamento"},
    height        = 400
)
fig1.update_layout(showlegend=False, xaxis_tickangle=-45)
st.plotly_chart(fig1, use_container_width=True)

st.divider()


st.subheader("🏆 Top 20 IPS con mejores resultados")

q2 = """
SELECT
    i.nombre_ips,
    ROUND(AVG(r.valor), 2)  AS promedio
FROM resultado r
JOIN ips i ON r.id_ips = i.id_ips
GROUP BY i.nombre_ips
ORDER BY promedio DESC
LIMIT 20
"""
df2 = run_query(q2)

col_a, col_b = st.columns([1, 2])

with col_a:
    st.dataframe(df2, use_container_width=True, hide_index=True)

with col_b:
    fig2 = px.bar(
        df2,
        x         = "promedio",
        y         = "nombre_ips",
        orientation = "h",
        color     = "promedio",
        color_continuous_scale = "Teal",
        labels    = {"promedio": "Promedio", "nombre_ips": "IPS"},
        height    = 500
    )
    fig2.update_layout(showlegend=False, yaxis=dict(autorange="reversed"))
    st.plotly_chart(fig2, use_container_width=True)

st.divider()


st.subheader("🩺 Distribución de registros por servicio")

q3 = """
SELECT
    s.nombre_servicio   AS servicio,
    COUNT(*)            AS total_registros
FROM resultado r
JOIN indicador ind ON r.id_indicador = ind.id_indicador
JOIN servicio  s   ON r.id_servicio  = s.id_servicio
GROUP BY s.nombre_servicio
ORDER BY total_registros DESC
"""
df3 = run_query(q3)

col_c, col_d = st.columns([1, 1])

with col_c:
    fig3 = px.pie(
        df3,
        names  = "servicio",
        values = "total_registros",
        color_discrete_sequence = px.colors.qualitative.Set2,
        height = 400
    )
    st.plotly_chart(fig3, use_container_width=True)

with col_d:
    st.dataframe(df3, use_container_width=True, hide_index=True)

st.divider()


st.subheader("🗺️ Promedio por municipio")

q4 = """
SELECT
    d.nombre_departamento           AS departamento,
    m.nombre_municipio              AS municipio,
    COUNT(DISTINCT i.id_ips)        AS total_ips,
    ROUND(AVG(r.valor), 2)          AS promedio_indicador
FROM resultado r
JOIN ips          i  ON r.id_ips          = i.id_ips
JOIN municipio    m  ON i.id_municipio    = m.id_municipio
JOIN departamento d  ON m.id_departamento = d.id_departamento
GROUP BY d.nombre_departamento, m.nombre_municipio
ORDER BY promedio_indicador DESC
"""
df4 = run_query(q4)

deptos = ["Todos"] + sorted(df4["departamento"].unique().tolist())
filtro = st.selectbox("Filtrar por departamento", deptos)

if filtro != "Todos":
    df4 = df4[df4["departamento"] == filtro]

st.dataframe(df4, use_container_width=True, hide_index=True)

st.divider()


st.subheader("📋 Registros por indicador y servicio")

q5 = """
SELECT
    s.nombre_servicio               AS servicio,
    ind.nombre_indicador            AS indicador,
    ind.unidad,
    COUNT(*)                        AS total_registros,
    ROUND(AVG(r.valor), 2)          AS promedio_resultado
FROM resultado r
JOIN indicador ind ON r.id_indicador = ind.id_indicador
JOIN servicio  s   ON r.id_servicio  = s.id_servicio
GROUP BY s.nombre_servicio, ind.nombre_indicador, ind.unidad
ORDER BY s.nombre_servicio, total_registros DESC
"""
df5 = run_query(q5)

fig5 = px.bar(
    df5,
    x             = "total_registros",
    y             = "indicador",
    color         = "servicio",
    orientation   = "h",
    labels        = {"total_registros": "Total registros", "indicador": "Indicador"},
    height        = 450,
    color_discrete_sequence = px.colors.qualitative.Pastel
)
fig5.update_layout(yaxis=dict(autorange="reversed"))
st.plotly_chart(fig5, use_container_width=True)


st.divider()
st.caption("Fuente: Clicsalud — Ministerio de Salud Colombia · clicsalud_ips")
