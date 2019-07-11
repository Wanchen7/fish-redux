import 'dart:async';

import 'package:flutter/widgets.dart' hide Action;

import '../redux/basic.dart';
import '../utils/utils.dart';
import 'basic.dart';

AdapterBuilder<T> asAdapter<T>(ViewBuilder<T> view) {
  return (T unstableState, Dispatch dispatch, ViewService service) {
    final ContextSys<T> ctx = service;
    return ListAdapter(
      (BuildContext buildContext, int index) =>
          view(ctx.state, dispatch, service),
      1,
    );
  };
}

Reducer<T> mergeReducers<T extends K, K>(Reducer<K> sup, [Reducer<T> sub]) {
  return (T state, Action action) {
    return sub?.call(sup(state, action), action) ?? sup(state, action);
  };
}

Effect<T> mergeEffects<T extends K, K>(Effect<K> sup, [Effect<T> sub]) {
  return (Action action, Context<T> ctx) {
    return sub?.call(action, ctx) ?? sup.call(action, ctx);
  };
}

/// combine & as
/// for action.type which override it's == operator
Reducer<T> asReducer<T>(Map<Object, Reducer<T>> map) => (map == null ||
        map.isEmpty)
    ? null
    : (T state, Action action) =>
        map.entries
            .firstWhere(
                (MapEntry<Object, Reducer<T>> entry) =>
                    action.type == entry.key,
                orElse: () => null)
            ?.value(state, action) ??
        state;

Reducer<T> filterReducer<T>(Reducer<T> reducer, ReducerFilter<T> filter) {
  return (reducer == null || filter == null)
      ? reducer
      : (T state, Action action) {
          return filter(state, action) ? reducer(state, action) : state;
        };
}

typedef SubEffect<T> = FutureOr<void> Function(Action action, Context<T> ctx);

/// for action.type which override it's == operator
Effect<T> combineEffects<T>(Map<Object, SubEffect<T>> map) =>
    (map == null || map.isEmpty)
        ? null
        : (Action action, Context<T> ctx) {
            final SubEffect<T> subEffect = map.entries
                .firstWhere(
                    (MapEntry<Object, SubEffect<T>> entry) =>
                        action.type == entry.key,
                    orElse: () => null)
                ?.value;

            /// false
            return subEffect?.call(action, ctx) ?? subEffect != null;
          };

ViewMiddleware<T> mergeViewMiddleware<T>(List<ViewMiddleware<T>> middleware) {
  return Collections.reduce<ViewMiddleware<T>>(middleware,
      (ViewMiddleware<T> first, ViewMiddleware<T> second) {
    return (AbstractComponent<dynamic> component, Store<T> store) {
      final Composable<ViewBuilder<dynamic>> inner = first(component, store);
      final Composable<ViewBuilder<dynamic>> outer = second(component, store);
      return (ViewBuilder<dynamic> view) {
        return outer(inner(view));
      };
    };
  });
}

AdapterMiddleware<T> mergeAdapterMiddleware<T>(
    List<AdapterMiddleware<T>> middleware) {
  return Collections.reduce<AdapterMiddleware<T>>(middleware,
      (AdapterMiddleware<T> first, AdapterMiddleware<T> second) {
    return (AbstractAdapter<dynamic> component, Store<T> store) {
      final Composable<AdapterBuilder<dynamic>> inner = first(component, store);
      final Composable<AdapterBuilder<dynamic>> outer =
          second(component, store);
      return (AdapterBuilder<dynamic> view) {
        return outer(inner(view));
      };
    };
  });
}

EffectMiddleware<T> mergeEffectMiddleware<T>(
    List<EffectMiddleware<T>> middleware) {
  return Collections.reduce<EffectMiddleware<T>>(middleware,
      (EffectMiddleware<T> first, EffectMiddleware<T> second) {
    return (AbstractLogic<dynamic> logic, Store<T> store) {
      final Composable<Effect<dynamic>> inner = first(logic, store);
      final Composable<Effect<dynamic>> outer = second(logic, store);
      return (Effect<dynamic> effect) {
        return outer(inner(effect));
      };
    };
  });
}