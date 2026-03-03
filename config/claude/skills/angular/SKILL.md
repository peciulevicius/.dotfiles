---
name: angular
description: Angular patterns and best practices. Use when working on Angular applications with TypeScript, services, components, RxJS, and routing.
---

You are an Angular expert. Apply these patterns.

## Component Patterns
```typescript
// Standalone components (Angular 17+, preferred)
@Component({
  selector: 'app-my',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  template: `...`
})

// Signals (Angular 17+, prefer over BehaviorSubject for local state)
readonly count = signal(0)
readonly doubled = computed(() => this.count() * 2)
increment() { this.count.update(c => c + 1) }

// Input/Output signals
readonly value = input.required<string>()
readonly change = output<string>()
```

## Services & RxJS
```typescript
@Injectable({ providedIn: 'root' })
export class DataService {
  private http = inject(HttpClient)

  getData(): Observable<Data[]> {
    return this.http.get<Data[]>('/api/data').pipe(
      catchError(err => { console.error(err); return EMPTY })
    )
  }
}

// In component — always unsubscribe
data$ = this.dataService.getData()
// Use async pipe in template: {{ data$ | async }}
// Or takeUntilDestroyed(): this.data$.pipe(takeUntilDestroyed()).subscribe(...)
```

## Reactive Forms
```typescript
form = new FormGroup({
  name: new FormControl('', [Validators.required, Validators.minLength(2)]),
  email: new FormControl('', [Validators.required, Validators.email])
})
// Template: [formGroup]="form" formControlName="name"
// Error: form.get('name')?.errors?.['required']
```

## Routing
```typescript
// Lazy loading (always use for feature modules/routes)
{ path: 'feature', loadComponent: () => import('./feature.component').then(m => m.FeatureComponent) }

// Guards
{ path: 'admin', canActivate: [authGuard], component: AdminComponent }

// Route data via inject
const router = inject(Router)
const route = inject(ActivatedRoute)
const id = route.snapshot.paramMap.get('id')
```

## HTTP Interceptors (Angular 15+)
```typescript
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const token = inject(AuthService).getToken()
  return next(token ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } }) : req)
}
```

## Legacy Patterns (Knockout/Razor context)
When updating legacy code:
- Prefer incremental migration over full rewrites
- New features in Angular, keep existing Knockout working
- Use Angular elements for embedding Angular in legacy pages: `createCustomElement()`

## Common Operators
- `switchMap` — cancel previous (search autocomplete, navigation)
- `mergeMap` — parallel (fire and forget)
- `concatMap` — sequential (ordered queue)
- `combineLatest` — combine multiple streams
- `shareReplay(1)` — cache last value for late subscribers
