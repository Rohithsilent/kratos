"""
FitnessGraph — LangGraph orchestrator for KRATOS AI.

Architecture:
    START → triage_node → [assistant | recovery | planner | nutrition | progression] → END

Each node is a specialised LangGraph node backed by its Agent class.
State flows through the graph and accumulates AI responses.
"""
from __future__ import annotations

from typing import TypedDict, Literal

from langgraph.graph import StateGraph, END, START
from loguru import logger

from app.ai.gateway.gemini_gateway import GeminiGateway
from app.ai.gateway.routing_service import RoutingService, RouteTarget


# ── Graph State ──────────────────────────────────────────────────────────────

class FitnessState(TypedDict):
    user_id: str
    message: str
    context: dict
    route: str
    response: str
    error: str | None


# ── Node Functions ────────────────────────────────────────────────────────────

def triage_node(state: FitnessState) -> FitnessState:
    """Route the incoming message to the correct specialist node."""
    router = RoutingService()
    target = router.route(state["message"])
    logger.debug("FitnessGraph.triage | user={} → {}", state["user_id"], target)
    return {**state, "route": target.value}


def _route_selector(state: FitnessState) -> Literal[
    "assistant", "recovery", "planner", "nutrition", "progression"
]:
    route_map = {
        RouteTarget.FLASH.value: "assistant",
        RouteTarget.PRO.value: "assistant",
        RouteTarget.RECOVERY_AGENT.value: "recovery",
        RouteTarget.PLANNER_AGENT.value: "planner",
        RouteTarget.NUTRITION_AGENT.value: "nutrition",
        RouteTarget.PROGRESSION_AGENT.value: "progression",
    }
    return route_map.get(state["route"], "assistant")


# ── Placeholder node stubs (replaced by real agents in Phase 2) ──────────────

def assistant_node(state: FitnessState) -> FitnessState:
    logger.debug("FitnessGraph → assistant_node")
    return {**state, "response": "[AssistantAgent — Phase 2]"}


def recovery_node(state: FitnessState) -> FitnessState:
    logger.debug("FitnessGraph → recovery_node")
    return {**state, "response": "[RecoveryAgent — Phase 2]"}


def planner_node(state: FitnessState) -> FitnessState:
    logger.debug("FitnessGraph → planner_node")
    return {**state, "response": "[PlannerAgent — Phase 2]"}


def nutrition_node(state: FitnessState) -> FitnessState:
    logger.debug("FitnessGraph → nutrition_node")
    return {**state, "response": "[NutritionAgent — Phase 2]"}


def progression_node(state: FitnessState) -> FitnessState:
    logger.debug("FitnessGraph → progression_node")
    return {**state, "response": "[ProgressionAgent — Phase 2]"}


# ── Graph Builder ─────────────────────────────────────────────────────────────

def build_fitness_graph() -> StateGraph:
    """Compile and return the KRATOS LangGraph fitness graph."""
    builder = StateGraph(FitnessState)

    # Register nodes
    builder.add_node("triage", triage_node)
    builder.add_node("assistant", assistant_node)
    builder.add_node("recovery", recovery_node)
    builder.add_node("planner", planner_node)
    builder.add_node("nutrition", nutrition_node)
    builder.add_node("progression", progression_node)

    # Edges
    builder.add_edge(START, "triage")
    builder.add_conditional_edges("triage", _route_selector, {
        "assistant":   "assistant",
        "recovery":    "recovery",
        "planner":     "planner",
        "nutrition":   "nutrition",
        "progression": "progression",
    })
    for node in ["assistant", "recovery", "planner", "nutrition", "progression"]:
        builder.add_edge(node, END)

    graph = builder.compile()
    logger.info("FitnessGraph compiled — nodes={}", 6)
    return graph


# Singleton
fitness_graph = build_fitness_graph()
