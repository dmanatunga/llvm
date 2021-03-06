; RUN: opt < %s  -instcombine -S | FileCheck %s


define  void @test(float* %a, float* readnone %a_end, i64 %b, float* %bf) unnamed_addr  {
entry:
  %cmp1 = icmp ult float* %a, %a_end
  %b.float = inttoptr i64 %b to float*
  br i1 %cmp1, label %bb1, label %bb2

bb1:
 br label %for.body.preheader
bb2:
 %bfi = ptrtoint float* %bf to i64
 br label %for.body.preheader

for.body.preheader:                               ; preds = %entry
  %b.phi = phi i64 [%b, %bb1], [%bfi, %bb2]
; CHECK-LABEL: for.body.preheader
; CHECK-NOT: %b.phi = phi i64
  br label %for.body

for.body:                                         ; preds = %for.body.preheader, %for.body
; CHECK-LABEL: for.body
  %a.addr.03 = phi float* [ %incdec.ptr, %for.body ], [ %a, %for.body.preheader ]
  %b.addr.float = phi float* [ %b.addr.float.inc, %for.body ], [ %b.float, %for.body.preheader ]
  %b.addr.i64 = phi i64 [ %b.addr.i64.inc, %for.body ], [ %b.phi, %for.body.preheader ]
; CHECK: %a.addr.03 = phi float* [ %incdec.ptr, %for.body ], [ %a, %for.body.preheader ]
; CHECK-NEXT:  %b.addr.float = phi float* [ %b.addr.float.inc, %for.body ], [ %b.float, %for.body.preheader ]
; CHECK-NOT: = %b.addr.i64
  %l = load float, float* %b.addr.float, align 4 
  %mul.i = fmul float %l, 4.200000e+01
  store float %mul.i, float* %a.addr.03, align 4
  %b.addr.float.2 = inttoptr i64 %b.addr.i64 to float*
; CHECK-NOT: inttoptr
  %b.addr.float.inc = getelementptr inbounds float, float* %b.addr.float.2, i64 1
  %b.addr.i64.inc = ptrtoint float* %b.addr.float.inc to i64
; CHECK-NOT: ptrtoint
  %incdec.ptr = getelementptr inbounds float, float* %a.addr.03, i64 1
  %cmp = icmp ult float* %incdec.ptr, %a_end
  br i1 %cmp, label %for.body, label %for.end

for.end:                                          ; preds = %for.body, %entry
  ret void
}



